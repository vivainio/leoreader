/*
 Copyright (c) 2013, Paul Houghton and Futurice Oy
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */
package org.tantalum;

import java.util.Vector;
import org.tantalum.util.L;

/**
 * A generic worker thread. Long-running and background tasks are queued and
 * executed here to keep the user interface thread free to update and respond to
 * incoming user interface events.
 * 
 * @author phou
 */
final class Worker extends Thread {

	/*
	 * Genearal forkSerial of tasks to be done by any Worker thread
	 */
	static final Vector q = new Vector();
	private static Worker[] workers;
	/*
	 * Higher priority forkSerial of tasks to be done only by this thread, in
	 * the exact order they appear in the serialQ. Other threads which don't
	 * have such dedicated compute to do will drop back to the more general q
	 */
	private final Vector serialQ;
	private static final Vector fastlaneQ = new Vector();
	private static final Vector backgroundQ = new Vector();
	private static final Vector shutdownQ = new Vector();
	private static int currentlyIdleCount = 0;
	private static boolean shuttingDown = false;
	private Task currentTask = null; // Access only within synchronized(q)
	private final boolean isBackgroundPriorityWorker;
	private final boolean isDedicatedFastlaneWorker;

	private Worker(final String name, final boolean addSerialQueue,
			final boolean isBackgroundPriorityWorker,
			final boolean isDedicatedFastlaneWorker) {
		super(name);

		this.isBackgroundPriorityWorker = isBackgroundPriorityWorker;
		this.isDedicatedFastlaneWorker = isDedicatedFastlaneWorker;
		if (addSerialQueue) {
			serialQ = new Vector();
		} else {
			serialQ = null;
		}
	}

	/**
	 * Initialize the Worker class at the start of your MIDlet.
	 * 
	 * Generally numberOfWorkers=2 is suggested, but you can increase this later
	 * when tuning your application's performance.
	 * 
	 * @param midlet
	 * @param numberOfWorkers
	 */
	static void init(final int numberOfWorkers) {
		workers = new Worker[numberOfWorkers];
		for (int i = 0; i < numberOfWorkers; i++) {
			workers[i] = new Worker("Worker" + i, i == 0, i == 1,
					i == numberOfWorkers - 1);
			workers[i].start();
		}
	}

	/**
	 * Task.HIGH_PRIORITY : Jump an object to the beginning of the forkSerial
	 * (LIFO - Last In First Out).
	 * 
	 * Note that this is best used for ensuring that operations holding a lot of
	 * memory are finished as soon as possible. If you are relying on this for
	 * performance, be warned that multiple calls to this method may still bog
	 * the system down.
	 * 
	 * Note also that under the rare circumstance that all Workers are busy with
	 * serialQueue() tasks, forkPriority() compute may be delayed. The
	 * recommended solution then is to either increase the number of Workers.
	 * You may also want to decrease reliance on serialQueue() elsewhere in you
	 * your program and make your application logic more parallel.
	 * 
	 * Worker.IDLE_PRIORITY : Add an object to be executed at low priority in
	 * the background on the worker thread. Execution will only begin when there
	 * are no foreground tasks, and only if at least 1 Worker thread is left
	 * ready for immediate execution of normal priority Tasks.
	 * 
	 * Items in the idleQueue will not be executed if shutdown() is called
	 * before they begin.
	 * 
	 * @param task
	 * @param priority
	 */
	static Task fork(final Task task, final int priority) {
		if (task.getStatus() != Task.PENDING) {
			throw new IllegalStateException(
					"Can not fork() a Task multiple times. Tasks are disposable, create a new instance each time: "
							+ task);
		}
		synchronized (q) {
			switch (priority) {
			case Task.FASTLANE_PRIORITY:
				fastlaneQ.insertElementAt(task, 0);
				/*
				 * Any thread will do as all will take Fastlane tasks, so
				 * notifyAll() is not needed
				 */
				q.notify();
				break;
			case Task.SERIAL_PRIORITY:
				workers[0].serialQ.addElement(task);
				q.notifyAll();
				break;
			case Task.HIGH_PRIORITY:
				q.insertElementAt(task, 0);
				q.notifyAll();
				break;
			case Task.NORMAL_PRIORITY:
				q.addElement(task);
				q.notifyAll();
				break;
			case Task.IDLE_PRIORITY:
				backgroundQ.addElement(task);
				q.notifyAll();
				break;
			case Task.SHUTDOWN:
				shutdownQ.addElement(task);
				q.notifyAll();
				break;
			default:
				throw new IllegalArgumentException("Illegal priority '"
						+ priority + "'");
			}

			return task;
		}
	}

	/**
	 * Take an object out of the pending task queue. If the task has already
	 * been started, or has not been fork()ed, or has been forkSerial() assigned
	 * to a dedicated thread queue, then this will return false.
	 * 
	 * @param task
	 * @return
	 */
	static boolean tryUnfork(final Task task) {
		boolean success;

		success = q.removeElement(task);
		if (!success) {
			success = fastlaneQ.removeElement(task);
		}
		if (!success) {
			success = backgroundQ.removeElement(task);
		}
		// #debug
		L.i("tryUnfork success=" + success, task.toString());

		return success;
	}

	/**
	 * Stop the specified task if it is currently running
	 * 
	 * @param task
	 * @return
	 */
	static void interruptTask(final Task task) {
		if (task == null) {
			throw new IllegalArgumentException(
					"interruptTask(null) not allowed");
		}
		synchronized (q) {
			final Thread currentThread = Thread.currentThread();

			for (int i = 0; i < workers.length; i++) {
				if (task.equals(workers[i].currentTask)) {
					if (currentThread == workers[i]) {
						// #debug
						L.i("Task attempted hard interrupt, usually cancel(true, ..), in itself",
								"The task is canceled, but will execute to the end. It if faster and more clear execution if you cancel(false, ..)");
						break;
					}
					// #debug
					L.i("Sending interrupt signal",
							"thread=" + workers[i].getName() + " task=" + task);
					if (task == workers[i].currentTask) {
						/*
						 * Note that there is no race condition here (risk the
						 * task ends before you interrupt it) because
						 * currentTask is a variable only accessed within a
						 * q-synchronized block and Worker.run() is hardened
						 * against stray interrupts
						 */
						workers[i].interrupt();
					}
					break;
				}
			}
		}
	}

	/**
	 * Call PlatformUtils.getInstance().shutdown() after all current queued and
	 * shutdown Tasks are completed. Resources held by the system will be closed
	 * and queued compute such as writing to the RMS or file system will
	 * complete.
	 * 
	 * @param block
	 *            Block the calling thread up to three seconds to allow orderly
	 *            shutdown. This is only needed in shutdown(true) which is
	 *            called for example by the user pressing the red HANGUP button.
	 */
	static void shutdown(final boolean block) {
		try {
			/*
			 * Removed queued tasks which can be removed
			 */
			synchronized (q) {
				shuttingDown = true;
				dequeueOrCancelOnShutdown(fastlaneQ);
				Worker.dequeueOrCancelOnShutdown(workers[0].serialQ);
				dequeueOrCancelOnShutdown(q);
				dequeueOrCancelOnShutdown(backgroundQ);
				q.notifyAll();
			}
			/*
			 * Interrupt currently running tasks which can be interrupted
			 */
			for (int i = 0; i < workers.length; i++) {
				final Task t = workers[i].currentTask;
				if (t != null
						&& t.getShutdownBehaviour() == Task.DEQUEUE_OR_CANCEL_ON_SHUTDOWN) {
					((Task) t)
							.cancel(true,
									"Shutdown signal received, hard cancel signal sent");
				}
			}

			if (block) {
				final long shutdownTimeout = System.currentTimeMillis();
				try {
					/*
					 * Block this thread up to 3 seconds while remaining tasks
					 * complete normally
					 */
					long timeRemaining;

					final int numWorkersToWaitFor = Thread.currentThread() instanceof Worker ? workers.length - 1
							: workers.length;
					synchronized (q) {
						while (currentlyIdleCount < numWorkersToWaitFor) {
							timeRemaining = shutdownTimeout + 3000
									- System.currentTimeMillis();
							if (timeRemaining <= 0) {
								// #debug
								L.i("A worker blocked shutdown timeout",
										Worker.toStringWorkers());
								break;
							}
							q.wait(timeRemaining);
						}
					}
				} finally {
					PlatformUtils
							.getInstance()
							.notifyDestroyed(
									"Blocking shutdown ending: shutdownTime="
											+ (System.currentTimeMillis() - shutdownTimeout));
				}
			}
		} catch (InterruptedException ex) {
			// #debug
			L.e("Shutdown was interrupted", "", ex);
		}
	}

	private static void dequeueOrCancelOnShutdown(final Vector queue) {
		if (queue == null) {
			return;
		}
		for (int i = queue.size() - 1; i >= 0; i--) {
			final Task t = (Task) queue.elementAt(i);

			switch (t.getShutdownBehaviour()) {
			case Task.EXECUTE_NORMALLY_ON_SHUTDOWN:
				break;

			case Task.DEQUEUE_OR_CANCEL_ON_SHUTDOWN:
			case Task.DEQUEUE_BUT_LEAVE_RUNNING_IF_ALREADY_STARTED_ON_SHUTDOWN:
				t.cancel(false,
						"Shutdown signal received, soft cancel signal sent");
				queue.removeElementAt(i);
				break;

			case Task.DEQUEUE_ON_SHUTDOWN:
				queue.removeElementAt(i);
				break;
			}
		}
	}

	/**
	 * For unit testing
	 * 
	 * @return
	 */
	public static int getNumberOfWorkers() {
		return workers.length;
	}

	// #mdebug
	private static String toStringWorkers() {
		final StringBuffer sb = new StringBuffer();

		sb.append("WORKERS: currentlyIdleCount=");
		sb.append(Worker.currentlyIdleCount);
		sb.append(" q.size()=");
		sb.append(Worker.q.size());
		sb.append(" shutdownQ.size()=");
		sb.append(Worker.shutdownQ.size());
		sb.append(" lowPriorityQ.size()=");
		sb.append(Worker.backgroundQ.size());

		for (int i = 0; i < workers.length; i++) {
			final Worker w = workers[i];
			if (w != null) {
				sb.append(" [");
				sb.append(w.getName());
				if (w.serialQ == null) {
					sb.append(" (no serialQ)");
				} else {
					sb.append(" serialQsize=");
					sb.append(w.serialQ.size());
				}
				sb.append(" currentTask=");
				sb.append(w.currentTask);
				sb.append("] ");
			}
		}

		return sb.toString();
	}

	// #enddebug

	/**
	 * Main worker loop. Each Worker thread pulls tasks from the common
	 * forkSerial.
	 * 
	 * The worker thread exits on uncaught errors or after shutdown() has been
	 * called and all pending tasks and shutdown tasks have completed.
	 */
	public void run() {
		try {
			while (true) {
				/*
				 * The following code is Thread-hardened such that
				 * Task.cancel(true, "blah") can generate a Thread.interrupt()
				 * at an point below _if_ currentTask is non-null and this
				 * Thread will recover and continue without side-effects such as
				 * re-running a canceled Task because of race a condition.
				 */
				try {
					final Task t;
					Object in = null;
					synchronized (q) {
						try {
							currentTask = null;

							if (!fastlaneQ.isEmpty()) {
								try {
									currentTask = (Task) fastlaneQ
											.firstElement();
								} finally {
									fastlaneQ.removeElementAt(0);
								}
							} else if (isDedicatedFastlaneWorker) {
							} else if (serialQ != null && !serialQ.isEmpty()) {
								try {
									currentTask = (Task) serialQ.firstElement();
								} finally {
									serialQ.removeElementAt(0);
								}
							} else {
								if (!q.isEmpty()) {
									// Normal compute, hardened against async
									// interrupt
									try {
										currentTask = (Task) q.firstElement();
									} finally {
										// Ensure we don't re-run in case of
										// interrupt
										q.removeElementAt(0);
									}
								} else if (shuttingDown) {
									if (!shutdownQ.isEmpty()) {
										// PHASE 1: Execute shutdown actions
										currentTask = (Task) shutdownQ
												.firstElement();
										shutdownQ.removeElementAt(0);
									} else {
										if (currentlyIdleCount == workers.length - 1) {
											// PHASE 2: Shutdown actions are all
											// complete
											PlatformUtils
													.getInstance()
													.notifyDestroyed(
															"currentlyIdleCount="
																	+ currentlyIdleCount);
											// #mdebug
											L.i("Log notifyDestroyed", "");
											L.shutdown();
											// #enddebug
										}
									}
								} else if (isBackgroundPriorityWorker
										&& backgroundQ.size() > 0
										&& currentlyIdleCount >= workers.length) {
									// Idle tasks- nothing else to do and other
									// threads have finished their ongoing tasks
									try {
										currentTask = (Task) backgroundQ
												.firstElement();
									} finally {
										backgroundQ.removeElementAt(0);
									}
								}
							}
						} finally {
							if (currentTask == null) {
								/*
								 * Nothing for this thread to do
								 */
								try {
									++currentlyIdleCount;
									q.wait();
								} finally {
									--currentlyIdleCount;
								}
							}
							t = currentTask;
						}
					}

					if (t != null) {
						t.executeTask(t.getValue());
					}
				} catch (InterruptedException e) {
					// #mdebug
					synchronized (q) {
						L.i("Worker interrupted by call to Task.cancel(true, \"blah\"",
								"Obscure race conditions can do this, but the code is hardened to deal with it and continue smoothly to the next task. task="
										+ currentTask);
					}
					// #enddebug
				} catch (Exception e) {
					// #mdebug
					synchronized (q) {
						L.e("Uncaught Task exception", "task=" + currentTask, e);
					}
					// #enddebug
				}
			}
		} catch (Throwable t) {
			// #mdebug
			synchronized (q) {
				L.e("Fatal worker error", "task=" + currentTask, t);
			}
			// #enddebug
		} finally {
			synchronized (q) {
				currentTask = null;
			}
		}
		// #debug
		L.i("Thread shutdown", "currentlyIdleCount=" + currentlyIdleCount);
	}

	// #mdebug
	static Vector getCurrentState() {
		synchronized (q) {
			final StringBuffer sb = new StringBuffer();
			final int n = Worker.getNumberOfWorkers();
			final Vector lines = new Vector(n + 1);

			for (int i = 0; i < n; i++) {
				final Worker w = Worker.workers[i];
				if (w != null) {
					final Task task = w.currentTask;
					sb.append(task != null ? 'o' : ' ');
				}
			}
			if (!fastlaneQ.isEmpty()) {
				sb.append('F');
				sb.append(fastlaneQ.size());
				sb.append('-');
			}
			if (!workers[0].serialQ.isEmpty()) {
				sb.append('S');
				sb.append(workers[0].serialQ.size());
				sb.append(' ');
			}
			if (!q.isEmpty()) {
				sb.append('Q');
				sb.append(Worker.q.size());
			}
			for (int i = 0; i < n; i++) {
				final Worker w = Worker.workers[i];
				if (w != null) {
					final Task task = w.currentTask;
					if (task != null) {
						lines.addElement(trimmedNameNoPackage(task.getClass()
								.getName()));
					}
				}
			}
			lines.insertElementAt(sb.toString(), 0);

			return lines;
		}
	}

	private static String trimmedNameNoPackage(String className) {
		final int i = className.lastIndexOf('.');

		if (i >= 0) {
			className = className.substring(i + 1);
		}

		return className;
	}
	// #enddebug
}