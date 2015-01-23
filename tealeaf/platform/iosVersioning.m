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
#import "platform/log.h"

#import <mach/mach.h>
#import <mach/mach_host.h>
#import <sys/types.h>
#import <sys/sysctl.h>

static NSString *m_platform = 0;

CEXPORT long get_platform_memory_limit()
{
  mach_port_t host_port;
  mach_msg_type_number_t host_size;
  vm_size_t pagesize;

  host_port = mach_host_self();
  host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
  host_page_size(host_port, &pagesize);

  vm_statistics_data_t vm_stat;
  
  if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
    NSLOG(@"{core} Failed to fetch vm statistics");
    
    return 50000000; // Default: 50 MB
  } else {
    /* Stats in bytes */
    long mem_used = (vm_stat.active_count +
                     vm_stat.inactive_count +
                     vm_stat.wire_count) * pagesize;
    long mem_free = vm_stat.free_count * pagesize;
    long mem_total = mem_used + mem_free;
    
    NSLOG(@"{core} Memory used: %ld free: %ld total: %ld", mem_used, mem_free, mem_total);
    
    // Return 50% of total memory (bytes)
    long limit = MIN((mem_total / 2), (200000000));
    
    NSLOG(@"{core} Texture memory limit set as low as %d", limit);
    
    return limit;
  }
}

// Get hw.machine
CEXPORT NSString *get_platform() {
	if (!m_platform) {
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *machine = (char*)malloc(size + 1);
		sysctlbyname("hw.machine", machine, &size, NULL, 0);
		machine[size] = '\0';
		m_platform = [NSString stringWithUTF8String:machine];
		free(machine);
	}

	// Should return a string like "iPhone4,1".  You can websearch for the other values and what they mean.
    return m_platform;
}

CEXPORT bool device_is_simulator() {
    NSString *model = [[UIDevice currentDevice] model];
    return [model isEqualToString:@"iPhone Simulator"];
}
