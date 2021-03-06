//
//  main.m
//  TrogonHelper
//
//  Created by Ricky Nelson on 12/31/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <syslog.h>
#include <xpc/xpc.h>

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    syslog(LOG_NOTICE, "Received event in helper.");
    
	xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
            
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
        
	} else {
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
        
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        xpc_dictionary_set_string(reply, "reply", "Hi there, host application!");
        xpc_connection_send_message(remote, reply);
	}
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        xpc_connection_t service = xpc_connection_create_mach_service("com.lark.software.TrogonHelper",
                                                                      dispatch_get_main_queue(),
                                                                      XPC_CONNECTION_MACH_SERVICE_LISTENER);
        
        if (!service) {
            syslog(LOG_NOTICE, "Failed to create service.");
            exit(EXIT_FAILURE);
        }
        
        syslog(LOG_NOTICE, "Configuring connection event handler for helper");
        xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
            __XPC_Connection_Handler(connection);
        });
        
        xpc_connection_resume(service);
        
        dispatch_main();
    }
    
    return EXIT_SUCCESS;
}

