const std = @import("std");

var global_id_counter: u64 = 0;

pub fn nextId() u64 {
    global_id_counter += 1;
    return global_id_counter;
}

pub fn timestampMs() i64 {
    return @as(i64, @intCast(nextId()));
}

pub const TaskPriority = enum(u2) {
    high = 0,
    normal = 1,
    low = 2,
};

pub const Task = struct {
    id: u64,
    name: []const u8,
    priority: TaskPriority,
    func: *const fn (*anyopaque) void,
    ctx: *anyopaque,
    next: ?*Task,
};

pub const TaskQueue = struct {
    head: ?*Task,
    tail: ?*Task,
    count: usize,

    pub fn init() TaskQueue {
        return .{ .head = null, .tail = null, .count = 0 };
    }

    pub fn enqueue(self: *TaskQueue, task: *Task) void {
        const priority = task.priority;
        var prev: ?*Task = null;
        var curr = self.head;
        while (curr) |c| : (curr = c.next) {
            if (@intFromEnum(c.priority) > @intFromEnum(priority)) break;
            prev = c;
        }
        task.next = curr;
        if (prev) |p| {
            p.next = task;
        } else {
            self.head = task;
        }
        if (curr == null) self.tail = task;
        self.count += 1;
    }

    pub fn dequeue(self: *TaskQueue) ?*Task {
        const task = self.head;
        if (task) |t| {
            self.head = t.next;
            if (self.head == null) self.tail = null;
            self.count -= 1;
        }
        return task;
    }

    pub fn isEmpty(self: *const TaskQueue) bool {
        return self.head == null;
    }
};

pub const ThreadPool = struct {
    allocator: std.mem.Allocator,
    threads: []std.Thread,
    queue: TaskQueue,
    quit: bool,
    mutex: std.Thread.Mutex,
    cond: std.Thread.Condition,

    pub fn init(allocator: std.mem.Allocator, num_threads: usize) !ThreadPool {
        var pool = ThreadPool{
            .allocator = allocator,
            .threads = try allocator.alloc(std.Thread, num_threads),
            .queue = TaskQueue.init(),
            .quit = false,
            .mutex = .{},
            .cond = .{},
        };
        for (pool.threads, 0..) |_, i| {
            pool.threads[i] = try std.Thread.spawn(.{}, workerFn, .{&pool});
        }
        return pool;
    }

    pub fn deinit(self: *ThreadPool) void {
        self.mutex.lock();
        self.quit = true;
        self.mutex.unlock();
        self.cond.broadcast();
        for (self.threads) |t| t.join();
        self.allocator.free(self.threads);
    }

    pub fn submit(self: *ThreadPool, task: *Task) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.queue.enqueue(task);
        self.cond.signal();
    }

    fn workerFn(pool: *ThreadPool) void {
        while (true) {
            pool.mutex.lock();
            while (pool.queue.isEmpty() and !pool.quit) {
                pool.cond.wait(&pool.mutex);
            }
            if (pool.quit) {
                pool.mutex.unlock();
                return;
            }
            const task = pool.queue.dequeue().?;
            pool.mutex.unlock();
            task.func(task.ctx);
        }
    }
};

pub const RunLoop = struct {
    allocator: std.mem.Allocator,
    pool: ThreadPool,
    tasks: TaskQueue,

    pub fn init(allocator: std.mem.Allocator) !RunLoop {
        return RunLoop{
            .allocator = allocator,
            .pool = try ThreadPool.init(allocator, 4),
            .tasks = TaskQueue.init(),
        };
    }

    pub fn deinit(self: *RunLoop) void {
        self.pool.deinit();
    }

    pub fn dispatch(self: *RunLoop, name: []const u8, priority: TaskPriority, func: *const fn (*anyopaque) void, ctx: *anyopaque) !void {
        const task = try self.allocator.create(Task);
        task.* = .{
            .id = @intFromPtr(task),
            .name = name,
            .priority = priority,
            .func = func,
            .ctx = ctx,
            .next = null,
        };
        self.pool.submit(task);
    }
};
