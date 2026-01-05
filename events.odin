package main

import "core:container/queue"
import "core:log"

Event :: struct {
	type:    Event_Type,
	payload: Event_Payload,
}

Event_Type :: enum {
	Unlocked_Door,
	Chest_Appeared,
	Started_Wall_Cling,
	Player_State_Change,
	Player_State_Transition,
}


Event_Player_State_Transition :: struct {
	exited:  Player_State,
	entered: Player_State,
}
Event_Player_State_Change_Payload :: struct {
	gained: bit_set[Player_Flag;u8],
	lost:   bit_set[Player_Flag;u8],
}
Event_Location_Payload :: struct {
	location: Vec2,
}

Event_Payload :: union {
	Event_Location_Payload,
	Event_Player_State_Change_Payload,
	Event_Player_State_Transition,
}

Event_Callback :: proc(event: Event)

init_events_system :: proc() {
	world.event_listeners = make(map[Event_Type][dynamic]Event_Callback, 8)
	queue.reserve(&world.event_queue, 16)
}

publish_event :: proc(type: Event_Type, payload: Event_Payload) {
	queue.enqueue(&world.event_queue, Event{type = type, payload = payload})
}

subscribe_event :: proc(type: Event_Type, callback: Event_Callback) {
	if type not_in world.event_listeners {
		// Allocate for 2 callbacks when we create our first listener, this could be changed
		world.event_listeners[type] = make([dynamic]Event_Callback, 0, 2)
	}
	append(&world.event_listeners[type], callback)
}

process_events :: proc() {
	// log.debugf("Processing Events: %v", queue.len(world.event_queue))
	for queue.len(world.event_queue) > 0 {
		event := queue.dequeue(&world.event_queue)
		// log.debugf("Popped Event Off the Queue: %v", event)
		if listeners, ok := world.event_listeners[event.type]; ok {
			for callback in listeners {
				callback(event)
			}
		}
	}
}
