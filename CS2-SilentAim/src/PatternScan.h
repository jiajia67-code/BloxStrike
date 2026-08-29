#pragma once
#include <Windows.h>
#include <cstdint>
#include <string>
#include <vector>
#include <Psapi.h>

namespace PatternScan
{
    // Module base + size info
    struct ModuleInfo
    {
        uintptr_t base;
        size_t size;
    };

    // Get module info from process
    inline ModuleInfo GetModuleInfo(const char* moduleName)
    {
        HMODULE hModule = GetModuleHandleA(moduleName);
        if (!hModule)
            return { 0, 0 };

        MODULEINFO modInfo;
        if (!GetModuleInformation(GetCurrentProcess(), hModule, &modInfo, sizeof(modInfo)))
            return { 0, 0 };

        return { (uintptr_t)modInfo.lpBaseOfDll, modInfo.SizeOfImage };
    }

    // Pattern scan with wildcard support
    // Pattern format: "48 89 5C 24 ? 48 89 6C 24" (? = wildcard)
    inline uintptr_t Scan(const char* moduleName, const char* pattern)
    {
        ModuleInfo info = GetModuleInfo(moduleName);
        if (info.base == 0 || info.size == 0)
            return 0;

        std::vector<int> patternBytes;
        std::vector<bool> patternMask;

        // Parse pattern string
        const char* current = pattern;
        while (*current)
        {
            if (*current == ' ')
            {
                current++;
                continue;
            }

            if (*current == '?')
            {
                patternBytes.push_back(0);
                patternMask.push_back(false); // wildcard
                current++;
                if (*current == '?') current++; // skip second ?
            }
            else
            {
                char hex[3] = { current[0], current[1], 0 };
                patternBytes.push_back(strtol(hex, nullptr, 16));
                patternMask.push_back(true); // exact match
                current += 2;
            }
        }

        if (patternBytes.empty())
            return 0;

        // Scan memory
        BYTE* base = (BYTE*)info.base;
        size_t scanSize = info.size - patternBytes.size();

        for (size_t i = 0; i < scanSize; i++)
        {
            bool found = true;
            for (size_t j = 0; j < patternBytes.size(); j++)
            {
                if (patternMask[j] && base[i + j] != patternBytes[j])
                {
                    found = false;
                    break;
                }
            }

            if (found)
                return (uintptr_t)(base + i);
        }

        return 0;
    }

    // Scan with relative address resolution (RIP-relative addressing)
    // Returns the resolved address from a ? ? ? ? wildcard pattern
    inline uintptr_t ScanRip(const char* moduleName, const char* pattern, int offset = 0)
    {
        uintptr_t addr = Scan(moduleName, pattern);
        if (addr == 0) return 0;

        // Read the 4-byte relative address at the wildcard position
        int32_t relativeAddr = *(int32_t*)(addr + offset);
        return addr + offset + 4 + relativeAddr;
    }
}
