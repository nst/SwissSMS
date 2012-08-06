#import <Foundation/Foundation.h>

#import <dlfcn.h>

#import <mach/vm_map.h>

#import <mach-o/dyld.h>
#import <mach-o/nlist.h>

#if defined(__i386__) || defined(__x86_64__)
typedef uint8_t instr_t;
#elif defined(__ppc__) || defined(__ppc64__)
typedef uint32_t instr_t;
#endif

typedef instr_t* instr_ptr;

static BOOL nodesForXPathIsWorking()
{
    BOOL isWorking;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:@"<utf8>☢</utf8>" options:0 error:nil] autorelease];
    NSArray *nodes = [doc nodesForXPath:@"/utf8[matches(text(), '☢')]" error:nil];
    
    isWorking = [nodes count] > 0;
    
    [pool release];
    
    return isWorking;
}

static BOOL fixXQuery(BOOL *wasBugged)
{
    instr_ptr pcre_compile = NULL;
    
    BOOL isWorking = nodesForXPathIsWorking();
    if (wasBugged) {
        *wasBugged = !isWorking;
    }
    
    if (isWorking) {
        return YES;
    }
    
    uint32_t i, count = _dyld_image_count();
        
    for(i = 0; i < count; i++) {
        const char* imageName = _dyld_get_image_name(i);
        if (strstr(imageName, "XQuery.framework")) {
            const struct mach_header *imageHeader = _dyld_get_image_header(i);
            
            // Find the address of the private symbol pcre_compile
#if defined(__LP64__)
#error 64 bits is not yet supported
#else
            struct nlist symlist[] = {{{"_pcre_compile"}, 0, 0, 0, 0}};
            if (nlist(imageName, symlist) == 0 && symlist[0].n_value != 0) {
                pcre_compile = (instr_ptr)((int)imageHeader + symlist[0].n_value);
            }
#endif
            break;
        }
    }
    
    if (pcre_compile == NULL) {
        return NO;
    }
    
#if defined(__i386__)
    // _pcre_compile+35: movl 0x0c(%ebp),%eax -> movl 0x18(%ebp),%eax
    //                   movl %eax,0x04(%esp)
    // pass the tableptr argument (arg5, which is null) instead of options (arg2) which is PCRE_UTF8 to pcre_compile2
    const instr_t original_instructions[7] = {0x8b, 0x45, 0x0c, 0x89, 0x44, 0x24, 0x04};
    const instr_t patched_instructions[7] =  {0x8b, 0x45, 0x18, 0x89, 0x44, 0x24, 0x04};
    instr_ptr instructions_addr = (unsigned char*)pcre_compile+35;
#elif defined(__ppc__)
    // _pcre_compile+0: or r0,r6,r6 -> li r4,0x0
    //                  or r8,r7,r7
    //                  or r6,r5,r5
    //                  or r7,r0,r0 -> or r7,r6,r6
    const instr_t original_instructions[4] = {0x7cc03378, 0x7ce83b78, 0x7ca62b78, 0x7c070378};
    const instr_t patched_instructions[4]  = {0x38800000, 0x7ce83b78, 0x7ca62b78, 0x7cc73378};
    instr_ptr instructions_addr = pcre_compile;
#else
    const instr_t original_instructions[0] = {};
    const instr_t patched_instructions[0]  = {};
    instr_ptr instructions_addr = NULL;
#endif
    
    if (memcmp(instructions_addr, original_instructions, sizeof(original_instructions)) == 0) {
        // Make it writable in order not to crash in the memcpy (EXC_BAD_ACCESS)
        kern_return_t vm_err = vm_protect(mach_task_self(), (vm_address_t)instructions_addr, sizeof(patched_instructions), false, VM_PROT_ALL);
        if (vm_err == KERN_SUCCESS) {
            memcpy(instructions_addr, patched_instructions, sizeof(patched_instructions));
        }
    }
    
    return nodesForXPathIsWorking();
}