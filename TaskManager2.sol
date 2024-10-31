// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract TaskManager2 {
    // Pending, InProgress, Done (012)
    enum TaskStatus {
        Pending,
        Inprogress,
        Done
    }

    struct Task {
        uint256 id;
        string title;
        TaskStatus status;
    }

    // variables
    // el array es dinámico
    Task[] public tasks;
    uint256 public taskCounter;
    uint256 constant MAX_TASK=10;

    // modificador que me diga el máximo que podemos tener
    modifier maxTask() {
        // que no pueda sobrepasar el valor 10
        require(taskCounter < MAX_TASK,"Me pase");
        _;
    }

    event taskCreated(uint256 indexed id, string title);

    // función crear una tarea
    function createTask(string calldata _title) external maxTask { 
        uint256 _taskCounter = taskCounter;     
        tasks.push(Task(_taskCounter, _title, TaskStatus.Pending));
        emit taskCreated(_taskCounter, _title);
        taskCounter ++;
        taskCounter = _taskCounter;
    }

    modifier existId(uint256 _id) {
        require(_id<taskCounter, "not exist");
        _;
    }

    // función update
    function updateStatus(uint256 _id, TaskStatus _status) external existId(_id) {
        tasks[_id].status = _status;
    }

    function readFirstPending() external view returns (Task memory) {
        uint256 Len = tasks.length;
        for(uint256 i=0; 5 < Len; i++) {
            if(tasks[i].status == TaskStatus.Pending) {
                tasks[i];
            }
        }
        return tasks[Len-1];
    }

}