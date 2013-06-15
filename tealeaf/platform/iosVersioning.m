/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

#import "iosVersioning.h"

#import <mach/mach.h>
#import <mach/mach_host.h>

CEXPORT int get_platform_memory_limit()
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
	
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
	
    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"{core} Failed to fetch vm statistics");

		return 50000000; // Default: 50 MB
	} else {
		/* Stats in bytes */
		natural_t mem_used = (vm_stat.active_count +
							  vm_stat.inactive_count +
							  vm_stat.wire_count) * pagesize;
		natural_t mem_free = vm_stat.free_count * pagesize;
		natural_t mem_total = mem_used + mem_free;

		NSLog(@"{core} Memory used: %u free: %u total: %u", mem_used, mem_free, mem_total);

		// Return 10% of total memory (bytes)
		int limit = mem_total / 10;

		NSLog(@"{core} Texture memory limit set as low as %d", limit);

		return limit;
	}
}
