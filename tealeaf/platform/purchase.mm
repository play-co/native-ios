/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Game Closure SDK.	 If not, see <http://www.gnu.org/licenses/>.
 */

#import "purchase.h"
#import "platform/log.h"

@implementation PurchaseApi


- (void)restore {
	if([self available]) {
		[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	}
}

- (void)buy:(NSString *)identifier {
	if([self available]) {
		SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:identifier]];
		request.delegate = self;
		[request start];
	}
}

- (void)finish:(SKPaymentTransaction *)transaction {
	if([self available]) {
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	}
}

- (bool)available {
	return [SKPaymentQueue canMakePayments];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	for (NSString *invalidProductId in response.invalidProductIdentifiers)
	{
		LOG("{purchase} ERROR: Invalid product id: %s" , [invalidProductId UTF8String]);
	}
	
	NSArray *products = response.products;
	if ([products count] > 0) {
		SKProduct* product = [products objectAtIndex:0];
		[[SKPaymentQueue defaultQueue] addPayment: [SKPayment paymentWithProduct:product]];
	} else {
		LOG("{purchase} ERROR: Purchase requested product not found");
	}
	[request autorelease];
}



@end
