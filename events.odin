package main

import "core:container/queue"
import "core:log"
import "tags"

Event :: struct {
	type:    Event_Type,
	payload: Event_Payload,
}

Event_Type :: enum {
	Player_State_Transition,
	Room_Change,
	Region_Change,
}


Event_Player_State_Transition :: struct {
	exited:  Player_State,
	entered: Player_State,
}

Event_Room_Change :: struct {
	new_room: tags.Room_Tag,
}
Event_Region_Change :: struct {
	new_region: tags.Region_Tag,
}

Event_Payload :: union {
	Event_Player_State_Transition,
	Event_Room_Change,
	Event_Region_Change,
}

Event_Callback :: proc(event: Event)

init_events_system :: proc() {
	world.event_listeners = make(map[Event_Type][dynamic]Event_Callback, 8)
	queue.reserve(&world.event_queue, 16)
}

delete_events_system :: proc() {
	for v in Event_Type {
		delete(world.event_listeners[v])
	}
	delete(world.event_listeners)
	queue.destroy(&world.event_queue)
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
