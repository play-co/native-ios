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

#import "PaymentObserver.h"
#import "jsPurchase.h"
#import "jsMacros.h"
#import "js_core.h"
#include "platform/log.h"

static PaymentObserver *m_payob = nil;

@implementation PaymentObserver

+ (PaymentObserver*) get {
	if (!m_payob) {
		m_payob = [[PaymentObserver alloc] init];
	}

	return m_payob;
}

+ (void) shutdown {
	if (m_payob) {
		[m_payob release];

		m_payob = nil;
	}
}

- (PaymentObserver*) init {
	self = [super init];

	self.store = [[[PurchaseApi alloc] init] autorelease];
	self.hooked = false;
	self.inFlight = [[[NSMutableDictionary alloc] init] autorelease];

	[self hookObserver];

	LOG("{payment} Initialized");

	return self;
}

- (void) dealloc {
	self.store = nil;
	self.inFlight = nil;

	if (self.hooked) {
		[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	}

	[super dealloc];
}

- (void)hookObserver {
	self.hooked = true;

	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (bool)marketAvailable {
	return [self.store available];
}

- (void) buy: (NSString*) identifier {
	[self.store buy:identifier];
}

- (void) restore {
	[self.store restore];
}

- (void) finishTransaction:(NSString *)transactionId {

	SKPaymentTransaction *transaction = [self.inFlight objectForKey:transactionId];

	if (transaction != nil) {
		[self.store finish:transaction];

		[self.inFlight removeObjectForKey:transactionId];
	}
}

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction* transaction in transactions) {

		// Normalize state codes to work the same way as on Android
		int stateCode = 0; // Success by default

		// If not success,
		if (transaction.transactionState != SKPaymentTransactionStatePurchased) {
			switch (transaction.error.code) {
			case SKPaymentTransactionStatePurchasing:
				// Should actually ignore this event because JS does not care
				return; // Ignore it!
			case SKPaymentTransactionStateFailed:
				// TODO: check if this means canceled, refunded, or expired
				stateCode = 1;
				break;
			case SKPaymentTransactionStateRestored:
				// TODO: This is a store-remembered thing that doesn't exist on Android so we need to add it eventually.
				// It would make a lot of sense to do this with our server instead of iTunes
				// But for now if we get this it actually should be handled like a successful purchase
				stateCode = 0;
				break;
			default:
				// Who knows what kind of state we are in here, assume an error occurred somewhere
				stateCode = 1;
				break;
			}
		}

		// Store it off
		[self.inFlight setObject:transaction forKey:transaction.transactionIdentifier];

		js_core *instance = [js_core lastJS];

		const char *product = [transaction.payment.productIdentifier UTF8String];
		const char *order = [transaction.transactionIdentifier UTF8String];
		const char *notifyId = order; // Code passed to finishTransaction

		// Strip store prefix
		{
			const char *storePrefix = [[instance.config objectForKey:@"bundle_id"] UTF8String];
			unsigned long storePrefixLen = (unsigned long)strlen(storePrefix);

			// If prefix matches,
			if (0 == strncmp(storePrefix, product, storePrefixLen)) {
				product += storePrefixLen + 1; // +1 for trailing dot.
			}
		}

		//TODO: USE JANSSON
		static const char *argFormat = "{\"name\":\"purchase\",\"state\":%d,\"product\":\"%s\",\"order\":\"%s\",\"notifyId\":\"%s\"}";
		int argLen = strlen(argFormat) + strlen(product) + strlen(order) + strlen(notifyId) + 20;
		char *args = (char*)malloc(sizeof(char) * argLen);
		snprintf(args, argLen, argFormat, stateCode, product, order, notifyId);

		// Run the JavaScript purchase event callback
		{
			jsval vevent[] = { STRING_TO_JSVAL(JS_NewStringCopyZ(instance.cx, args)) };
			[instance dispatchEvent:vevent count:1];
		}
		free(args);
	}
}

@end
