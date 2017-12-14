#import "MyOCPPHeader.h"
#include "SomeCPPHeader.hpp"

@implementation MyOCPPClass

- (void)printHelloWorldFromCPP {
    CPPTester helloPrinter;
    helloPrinter.printHelloWorld();
}

@end
