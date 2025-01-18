# Function to extract a variable from the Makefile.
function(extract_makefile_variable var_name out_var)
    string(REGEX MATCH "${var_name} = ([^\n]*)" match ${STM32CUBEMX_MAKEFILE})
    if (match)
        string(STRIP "${CMAKE_MATCH_1}" match)
        set(${out_var} ${match} PARENT_SCOPE)
    else()
        set(${out_var} "" PARENT_SCOPE)
    endif()
endfunction()

# Function to extract a list of flag from the Makefile. 
function(extract_makefile_flag var_name out_list leading)
    extract_makefile_variable(${var_name} temp)
    # Split the list into items by spaces 
    string(REPLACE " " ";" temp ${temp})
    # Filter out items that don't start with `leading`
    foreach(item ${temp})
        if (item)
            if (item MATCHES "^${leading}")
                string(REGEX REPLACE "^${leading}" "" item ${item})
                list(APPEND output ${item})
            endif()
        endif()
    endforeach()
    set(${out_list} ${output} PARENT_SCOPE)
endfunction()
