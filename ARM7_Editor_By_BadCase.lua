-------------------------------------------------
-- HEX to ARM Convertor
-- Start
-------------------------------------------------

-------------------------------------------------
-- Instruction parts decoding functions
-- Start
-------------------------------------------------

-- function by CmP
-- Parses register and returns it's number
-- bits - a string of 4 bits that represents register number
local function parse_register( bits )
    if type( bits ) ~= 'string' then
        error( 'Wrong type of the argument' )
    end
    if #bits ~= 4 then
        error( 'Wrong length of the string' )
    end
    if bits:match( '[^01]' ) then
        error( 'Argument is not a binary string' )
    end
    
    return tonumber( bits, 2 )
end

-- function by CmP
-- Parses constant and returns it's numeric value
-- bits - a string of 12 bits that represents constant
local function parse_constant( bits )
    if type( bits ) ~= 'string' then
        error( 'Wrong type of the argument' )
    end
    if #bits ~= 12 then
        error( 'Wrong length of the string' )
    end
    if bits:match( '[^01]' ) then
        error( 'Argument is not a binary string' )
    end
    
    local imm = tonumber( bits:sub( 5, 12 ), 2 )
    local rotate = tonumber( bits:sub( 1, 4 ), 2 )
    return bit32.rrotate( imm, rotate * 2 )
end

-- function by CmP
-- Parses register list and returns array of register numbers
-- bits - a string of 16 bits that represents register list
local function parse_register_list( bits )
    if type( bits ) ~= 'string' then
        error( 'Wrong type of the argument' )
    end
    if #bits ~= 16 then
        error( 'Wrong length of the string' )
    end
    if bits:match( '[^01]' ) then
        error( 'Argument is not a binary string' )
    end
        
    local reg_num_list = {}
    for i = #bits, 1, -1 do
        if bits:sub( i, i ) == '1' then
            reg_num_list[#reg_num_list + 1] = 16 - i
        end
    end
    return reg_num_list
end

local function register_list_to_string( reg_list )
    local str = ''
    local reg_list_size = #reg_list
    
    if reg_list_size == 0 then
        return '{}'
    end	
    str = '{'
    for i = 1, reg_list_size - 1 do
        str = str ..'R'.. reg_list[i] .. ', R'
    end
    str = str .. reg_list[reg_list_size] .. '}'	
    return str
end

-------------------------------------------------
-- Instruction parts decoding functions
-- End
-------------------------------------------------

function hex_num( v )
    return hex( tonumber( v, 2 ) )
end

function search_binary( search_string, current_binary )
    return string.find( current_binary, search_string )
end

function toHexString( n )
    return string.format( '%08X', n ):sub( -8 )
end

function hex( n )
    return string.format( '%X', n )
end

function dword_to_binary( dword )
    if dword == 0 then
        return '00000000000000000000000000000000'
    else
    local n = '0x'..toHexString( dword )
    local binary_string = ''
    local t, d = {}, 0
    local d = math.log( n )/math.log( 2 ) -- binary logarithm
    
    for i=math.floor( d+1 ),0,-1 do
        t[#t+1] = math.floor( n / 2^i )
        n = n % 2^i
    end
    for i, v in pairs( t ) do
        if i > 1 then
        binary_string = binary_string..string.sub( v, 0, -3 )
        end
    end
        binary_string = string.format( "%032s", binary_string )
    return binary_string
    end
end

function arm_convertor( dword_or_hex )
    if type(dword_or_hex) ~= 'number' then
        dword_or_hex = tonumber( '0x'..dword_or_hex:gsub( "(..)(..)(..)(..)", "%4%3%2%1" ) )
    end

    local current_binary = dword_to_binary( dword_or_hex )

    if search_binary( '11100001001011111111111100011110', current_binary ) then
        return decode_bxlr( current_binary )
    elseif search_binary( '111010001000....................', current_binary ) then
        return decode_stm( current_binary )
    elseif search_binary( '111000.10101....................', current_binary ) then
        return decode_cmp( current_binary )
    elseif search_binary( '111000.1111.....................', current_binary ) then
        return decode_mvn( current_binary )
    elseif search_binary( '00011010.......................', current_binary ) then
        return decode_bne( current_binary )
    elseif search_binary( '000000011001....................', current_binary ) then
        return decode_orrseq( current_binary )					   
    elseif search_binary( '00001010........................', current_binary ) then
        return decode_beq( current_binary )				   
    elseif search_binary( '10001010........................', current_binary ) then
        return decode_bhi( current_binary )
    elseif search_binary( '11101010........................', current_binary ) then
        return decode_b( current_binary )			   
    elseif search_binary( '111001.1.000....................', current_binary ) then
        return decode_str( current_binary )
    elseif search_binary( '00000001........................', current_binary ) then
        return decode_mvnseq( current_binary )
    elseif search_binary( '111000110001....................', current_binary ) then
        return decode_tst( current_binary )
    elseif search_binary( '00010011........................', current_binary ) then
        return decode_movwne( current_binary )
    elseif search_binary( '111011101111....................', current_binary ) then
        return decode_vmrs( current_binary )
    elseif search_binary( '111011100000....................', current_binary ) then
        return decode_vmov( current_binary )
    elseif search_binary( '111011101011....................', current_binary ) then
        return decode_vcmpef32( current_binary )
    elseif search_binary( '11001000........................', current_binary ) then
        return decode_popgt( current_binary )
    elseif search_binary( '11000011........................', current_binary ) then
        return decode_movgt( current_binary )				   
    elseif search_binary( '111001.1.100....................', current_binary ) then
        return decode_strb( current_binary )
    elseif search_binary( '111000010010....................', current_binary ) then
        return decode_blx( current_binary )					   
    elseif search_binary( '11101011........................', current_binary ) then
        return decode_bl( current_binary )					   
    elseif search_binary( '111000.1.101....................', current_binary ) then
        return decode_ldrh( current_binary )						   
    elseif search_binary( '111001.1.101....................', current_binary ) then
        return decode_ldrb( current_binary )	
    elseif search_binary( '111001.1.001....................', current_binary ) then
        return decode_ldr( current_binary )	
    elseif search_binary( '111000000000....................', current_binary ) then
        return decode_mul( current_binary )		
    elseif search_binary( '111000.00100....................', current_binary ) then
        return decode_sub( current_binary )								   
    elseif search_binary( '001100.0.000....................', current_binary ) then
        return decode_addcc( current_binary )
    elseif search_binary( '111000.01000....................', current_binary ) then
        return decode_add( current_binary )		
    elseif search_binary( '1110100010111101................', current_binary ) then
        return decode_pop( current_binary )		
    elseif search_binary( '1110100100101101................', current_binary ) then
        return decode_push( current_binary )							   
    elseif search_binary( '111001.0.111....................', current_binary ) then
        return decode_uxth( current_binary )					   
    elseif search_binary( '111000.10000....................', current_binary ) then
        return decode_movw( current_binary )					   
    elseif search_binary( '111000.10100....................', current_binary ) then
        return decode_movt( current_binary )					
    elseif search_binary( '111000.00010....................', current_binary ) then
        return decode_eor( current_binary )  
    elseif search_binary( '111000.11010....................', current_binary ) then
        return decode_mov( current_binary )
    else
      local bit1to4 = current_binary:sub( 1, 4 )
      local bit5to8 = current_binary:sub( 5, 8 )
      local bit9to12 = current_binary:sub( 9, 12 )
      local bit13to16 = current_binary:sub( 13, 16 )
      local bit17to20 = current_binary:sub( 17, 20 )
      local bit21to24 = current_binary:sub( 21, 24 )
      local bit25to28 = current_binary:sub( 25, 28 )
      local bit29to32 = current_binary:sub( 29, 32 )
      return '❓ '..bit1to4..bit5to8..' | '..bit9to12..' | '..bit13to16..' | '..bit17to20..' | '..bit21to24..' | '..bit25to28..' | '..bit29to32..' ❓'
      --return 'Not Found'
    end
end

function get_literal_number( current_binary )
    local literal_string = tonumber(current_binary:sub( 13, 16 )..current_binary:sub( 21, 32 ), 2 )
    return literal_string
end

function return_opcode( opcode_type, reg_one, reg_two, reg_three )
    if opcode_type == 'LDR' or opcode_type == 'LDRH' or opcode_type == 'LDRB' or opcode_type == 'STR'  or opcode_type == 'STRB' then
        bracket1 = '['
        bracket2 = ']'
    else
        bracket1 = ''
        bracket2 = ''
    end
    local a_count = 0
        local build_arm_string =  opcode_type
        if reg_one then
            build_arm_string =  build_arm_string..' '..reg_one
        end
        if reg_two then
            build_arm_string =  build_arm_string..', '..bracket1..reg_two
        end
    if reg_three then
        build_arm_string = build_arm_string..', '..reg_three..bracket2
    else
        build_arm_string = build_arm_string..bracket2
    end
    return build_arm_string
end

-------------------------------------------------
-- Instruction decoding functions
-- Start
-------------------------------------------------

function decode_bxlr( binary_string )
    local opcode_type = 'BX LR'	
    return opcode_type
end 

function decode_bne( binary_string )
    local opcode_type = 'BNE'	
    local number_value = tonumber( binary_string:sub( 9, 32 ), 2 ) * 4 + 8
    return opcode_type..' #'..number_value
end 

function decode_orrseq( binary_string )
    local opcode_type = 'ORRSEQ'	
    return '🚧 '..return_opcode( opcode_type )
end 

function decode_b( binary_string )
    local number_value = ''
    local opcode_type = 'B'	
    if binary_string:sub( 9, 12 ) == '1111' then
        number_value = '- value'
    else
        number_value = tonumber( binary_string:sub( 9, 32 ), 2 ) * 4 + 8
    end
    return '🚧 '..opcode_type..' #'..number_value
end 

function decode_bhi( binary_string )
    local number_value = ''
    local opcode_type = 'BHI'	
    if binary_string:sub( 9, 12 ) == '1111' then
        number_value = '- value'
    else
        number_value = tonumber( binary_string:sub( 9, 32 ), 2 ) * 4 + 8
    end
    return '🚧 '..opcode_type..' #'..number_value
end 

function decode_beq( binary_string )
    local number_value = ''
    local opcode_type = 'BEQ'	
    if binary_string:sub( 9, 12 ) == '1111' then
        number_value = '- value'
    else
        number_value = tonumber( binary_string:sub( 9, 32 ), 2 ) * 4 + 8
    end
    return '🚧 '..opcode_type..' #'..number_value
end 

function decode_mvnseq( binary_string )
    local opcode_type = 'MVNSEQ'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_tst( binary_string )
    local reg_two = ''
    local opcode_type = 'TST'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
    else
        reg_two = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
    end	
    return return_opcode( opcode_type, reg_one, reg_two )
end

function decode_movwne( binary_string )
    local opcode_type = 'MOVWNE'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_vmrs( binary_string )
    local opcode_type = 'VMRS'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_vmov( binary_string )
    local opcode_type = 'VMOV'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_vcmpef32( binary_string )
    local opcode_type = 'VCMPEF32'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_popgt( binary_string )
    local opcode_type = 'POPGT'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_movgt( binary_string )
    local opcode_type = 'MOVGT'	
    return '🚧 '..return_opcode( opcode_type )
end

function decode_bl( binary_string )
    local opcode_type = 'BL'
    if binary_string:sub( 9, 12 ) == '1111' or binary_string:sub( 9, 12 ) == '1110' then
        number_value = '- value'
    else
        number_value = tonumber( binary_string:sub( 9, 32 ),2 ) * 4 + 8
    end
    return '🚧 '..opcode_type..' #'..number_value
end

function decode_ldr( binary_string ) 
    local negative = ''
    local opcode_type = 'LDR'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 9, 9 ) == '0' then
        negative = '-'
        else
        negative = ''
    end
    if binary_string:sub( 7, 7 ) == '0'  and tonumber( binary_string:sub( 21, 32 ), 2 ) ~= 0 then
        local reg_three = '#' ..negative.. tonumber( binary_string:sub( 21, 32 ), 2 )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )

    elseif binary_string:sub( 7, 7 ) == '1' and binary_string:sub( 25, 28 ) == '0000' then
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        return return_opcode( opcode_type, reg_one, reg_two )
    end
end

function decode_ldrb( binary_string ) 
    local negative = ''
    local opcode_type = 'LDRB'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 9, 9 ) == '0' then
        negative = '-'
        else
        negative = ''
    end
    if binary_string:sub( 7, 7 ) == '0' and tonumber( binary_string:sub( 21, 32 ), 2 ) ~= 0 then
        local reg_three = '#' ..negative.. tonumber( binary_string:sub( 21, 32 ), 2 )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    elseif binary_string:sub( 7, 7 ) == '1' then
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        return return_opcode( opcode_type, reg_one, reg_two )
    end
end

function decode_ldrh( binary_string ) 
    local negative = ''
    local opcode_type = 'LDRH'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 9, 9 ) == '0' then
        negative = '-'
        else
        negative = ''
    end
    if binary_string:sub( 7, 7 ) == '0'  and tonumber( binary_string:sub( 21, 32 ), 2 ) ~= 0 then
        local reg_three = '#' ..negative.. tonumber( binary_string:sub( 21, 32 ), 2 )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    elseif binary_string:sub( 7, 7 ) == '1' then
        reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        return return_opcode( opcode_type, reg_one, reg_two )
    end
end

function decode_strb( binary_string ) 
    local negative = ''
    local opcode_type = 'STRB'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 9, 9 ) == '0' then
        negative = '-'
        else
        negative = ''
    end
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_three = '#' ..negative.. tonumber( binary_string:sub( 21, 32 ), 2 )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    end
end

function decode_str( binary_string ) 
    local negative = ''
    local opcode_type = 'STR'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 9, 9 ) == '0' then
        negative = '-'
        else
        negative = ''
    end
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_three = '#' ..negative.. tonumber( binary_string:sub( 21, 32 ), 2 )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    end
end

function decode_mul( binary_string )
    local opcode_type = 'MUL'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
    local reg_three = 'R' .. parse_register( binary_string:sub( 21, 24 ) )
    return return_opcode( opcode_type, reg_one, reg_two, reg_three )
end

function decode_stm( binary_string )
    local opcode_type = 'STM'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    local reg_two = register_list_to_string( parse_register_list( binary_string:sub( 17, 32 ) ) )	
    return return_opcode( opcode_type, reg_one, reg_two )
end

function decode_pop( binary_string )
    local opcode_type = 'POP'	
    local reg_one = register_list_to_string( parse_register_list( binary_string:sub( 17, 32 ) ) )	
    return return_opcode( opcode_type, reg_one )
end

function decode_push( binary_string )
    local opcode_type = 'PUSH'	
    local reg_one = register_list_to_string( parse_register_list( binary_string:sub( 17, 32 ) ) )
    return return_opcode( opcode_type, reg_one )
end

function decode_sub( binary_string )
    local opcode_type = 'SUB'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        local reg_three = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    end
end

function decode_addcc( binary_string )
    local opcode_type = 'ADDCC'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        local reg_three = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    end
end

function decode_add( binary_string )
    local opcode_type = 'ADD'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        local reg_three = '#' .. parse_constant( binary_string:sub( 21, 32) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    end
end

function decode_mov( binary_string )
    local opcode_type = 'MOV'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    else
        local reg_two = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    end	
end

function decode_eor( binary_string )
    local opcode_type = 'EOR'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    local reg_two = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_three = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    else
        local reg_three = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two, reg_three )
    end
end

function decode_movt( binary_string )
    local opcode_type = 'MOVT'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    else
        local reg_two = '#' .. get_literal_number( binary_string )
        return return_opcode( opcode_type, reg_one, reg_two )
    end	
end

function decode_movw( binary_string )
    local opcode_type = 'MOVW'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    else
        local reg_two = '#' .. get_literal_number( binary_string )
        return return_opcode( opcode_type, reg_one, reg_two )
    end	
end

function decode_blx( binary_string )
    local opcode_type = 'BLX'	
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_one = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one )
    else
        local reg_one = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one )
    end	
end

function decode_uxth( binary_string )
    local opcode_type = 'UXTH'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    else
        local reg_two = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    end	
end

function decode_mvn( binary_string )
    local opcode_type = 'MVN'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 17, 20 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    else
        local reg_two = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    end	
end

function decode_cmp( binary_string )
    local opcode_type = 'CMP'	
    local reg_one = 'R' .. parse_register( binary_string:sub( 13, 16 ) )
    if binary_string:sub( 7, 7 ) == '0' then
        local reg_two = 'R' .. parse_register( binary_string:sub( 29, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    else
        local reg_two = '#' .. parse_constant( binary_string:sub( 21, 32 ) )
        return return_opcode( opcode_type, reg_one, reg_two )
    end
end

-------------------------------------------------
-- Instruction decoding functions
-- End
-------------------------------------------------

-------------------------------------------------
-- HEX to ARM Convertor
-- End
-------------------------------------------------

-------------------------------------------------
-- ARM to HEX Convertor
-- Start
-------------------------------------------------

function get_opcode_binary_string( opcode, reg1, reg2, reg3 )
    local current_binary_string = ''
    local binary_string_array  =
    {
        ['ADD'] = {
        ['constant'] = '111000101000reg2reg1last12bits',
        ['register3'] = '111000001000reg2reg100000000reg3'	
        },
        ['MOV'] = {
        ['constant'] = '1110001110100000reg1last12bits',
        ['register'] = '1110000110100000reg100000000reg2'
        },
        ['MOVW'] = {
        ['constant'] = '111000110000hex1reg1hex2hex3hex4',
        },			
        ['SUB'] = {
        ['constant'] = '111000100100reg2reg1last12bits',
        ['register3'] = '111000000100reg2reg100000000reg3'
        },			
        ['TST'] = {
        ['constant'] = '111000110001reg10000last12bits',
        ['register'] = '111000010001reg1000000000000reg2'
        },			
        ['CMP'] = {
        ['constant'] = '111000110101reg10000last12bits',
        ['register'] = '111000010101reg1000000000000reg2'
        },			
        ['STR'] = {
        ['register'] = '111001011000reg2reg1000000000000',
        ['register3'] = '111001111000reg2reg100000000reg3'
        },			
        ['STRB'] = {
        ['register'] = '111001011100reg2reg1000000000000',
        ['register3'] = '111001111100reg2reg100000000reg3'
        },			
        ['LDR'] = {
        ['register'] = '111001011001reg2reg1000000000000',
        ['register3'] = '111001111001reg2reg100000000reg3'
        },			
        ['LDRB'] = {
        ['register'] = '111001011101reg2reg1000000000000',
        ['register3'] = '111001111101reg2reg100000000reg3'
        },			
        ['EOR'] = {
        ['register'] = '111000000010reg1reg100000000reg2',
        ['register3'] = '111000000010reg2reg100000000reg3'
        },			
        ['MOVGT'] = {
        ['register'] = '1100000110100000reg100000000reg2'
        },			
        ['MUL'] = {
        ['register'] = '111000000000reg10000reg31001reg2'
        }
    }
    if type(reg3) == 'number' or type(reg2) == 'number' then
        current_binary_string = binary_string_array[opcode]['constant']
    else
        if reg3 == false then
        current_binary_string = binary_string_array[opcode]['register']
        else
        current_binary_string = binary_string_array[opcode]['register3']	
        end
    end		
    return current_binary_string
end

local function number_to_binary_string( num )
    local binary_string = ''
    local t = {}
    local d = math.log( num ) / math.log( 2 ) -- binary logarithm
    
    for i = math.floor( d+1 ), 0, -1 do
        t[#t+1] = math.floor( num / 2^i )
        num = num % 2^i
    end
    for i, v in ipairs( t ) do
        if i > 1 then
            binary_string = binary_string .. string.sub( v, 0, -3 )
        end
    end
    return binary_string
end

local function encode_constant( num )
    local encoded_number = 0
    local imm_part = 0
    local binary_string = ''
    local str_len = 0
    
    for i = 0, 15 do		
    imm_part = bit32.lrotate(num, i * 2)
        if imm_part < 256 then
            encoded_number = (i << 8) | imm_part
            binary_string = number_to_binary_string(encoded_number)
            str_len = #binary_string
            if str_len < 12 then
                binary_string = string.rep( '0', 12 - str_len ) .. binary_string
            end
            return binary_string
        end
    end	
    return nil
end

function hex_char_to_binary( hex_char )
    if hex_char == '0' then
    return '0000'
    else
    local n = '0x'..hex_char
    local binary_string = ''
    local t, d = {}, 0
    local d = math.log( n )/math.log( 2 ) -- binary logarithm
    
    for i=math.floor( d+1 ),0,-1 do
        t[#t+1] = math.floor( n / 2^i )
        n = n % 2^i
    end
    for i, v in pairs( t ) do
        if i > 1 then
        binary_string = binary_string..string.sub( v, 0, -3 )
        end
    end
    return binary_string
    end
end

function encode_literal_constant( num )
    local literal_array = {}
    local hex_encoded_num = string.format( '%04X', num ):sub( -4 )
    for c in hex_encoded_num:gmatch"." do
        table.insert( literal_array, string.format( "%04s", hex_char_to_binary( c ) ) );
    end
    return literal_array
end
function opcode_generator( opcode, reg1, reg2, reg3 )
    local reverse_hex =''
    local binary_string = '' 
    local last12bits = ''
    if opcode == 'NOP' or opcode == 'BX LR' then
        local no_reg_array = {['NOP']='00F020E3',['BX LR']='1EFF2FE1'}
        reverse_hex = no_reg_array[opcode]
    else
    local current_binary_string = get_opcode_binary_string( opcode, reg1, reg2, reg3 )
    
    current_binary_string = string.gsub( current_binary_string, 'reg1', reg1 )
    current_binary_string = string.gsub( current_binary_string, 'reg2', reg2 )
    current_binary_string = string.gsub( current_binary_string, 'reg3', reg3 )		
    if type( reg2 ) == 'number' or type( reg3 ) == 'number' then
        if type( reg2 ) == 'number' then
        number_value = reg2
        elseif type( reg3 ) == 'number' then
        number_value = reg3
        end
        
        if opcode == 'MOVW' then
            literal_number = encode_literal_constant( number_value )
            current_binary_string = string.gsub( current_binary_string, 'hex1', literal_number[1] )	
            current_binary_string = string.gsub( current_binary_string, 'hex2', literal_number[2] )	
            current_binary_string = string.gsub( current_binary_string, 'hex3', literal_number[3] )	
            current_binary_string = string.gsub( current_binary_string, 'hex4', literal_number[4] )	
        else
            if encode_constant(number_value) ~= nil then
                last12bits = encode_constant( number_value )
            else
                return gg.alert( 'ℹ️ Not a valid constant for this OpCode ℹ️' )
            end
            current_binary_string = string.gsub( current_binary_string, 'last12bits', last12bits )	
        end
    end		
    bin_to_num = tonumber( current_binary_string, 2 )
    reverse_hex = toHexString( bin_to_num ):gsub( "(..)(..)(..)(..)", "%4%3%2%1" )
    end
    return reverse_hex
    --gg.copyText( reverse_hex )
    --gg.alert( reverse_hex )
end

function check_if_reg_3_required( opcode )
    if opcode == 'MOV' then
        required = false
    end
    if opcode == 'MOVW' then
        required = false
    end
    if opcode == 'MOVGT' then
        required = false
    end
    if opcode == 'ADD' then
        required = true
    end
    if opcode == 'SUB' then
        required = true
    end
    if opcode == 'CMP' then
        required = false
    end
    if opcode == 'MUL' then
        required = true
    end
    if opcode == 'LDR' then
        required = false
    end
    if opcode == 'LDRB' then
        required = false
    end
    if opcode == 'STRB' then
        required = false
    end	
    if opcode == 'STR' then
        required = false
    end	
    if opcode == 'VMOV' then
        required = false
    end	
    if opcode == 'TST' then
        required = false
    end	
    if opcode == 'EOR' then
        required = false
    end	
    return required
end

-------------------------------------------------
-- ARM to HEX Convertor
-- End
-------------------------------------------------

-------------------------------------------------
-- HEX to ARM GUI
-- Start
-------------------------------------------------

function build_menu( base_address, base_offset, next_page )
    local lib_offset = tonumber( '0x'..base_address )	
    if next_page ~= '0' then
        lib_offset = next_page	
    else
    end
    local fcount = 1
    local offset_count = 0	
    
    menu_array = {}
    arm_array = {}
    
    repeat
        arm_array[fcount] = {}
        arm_array[fcount].address = lib_offset + offset_count
        arm_array[fcount].flags =  gg.TYPE_DWORD		
        offset_count = offset_count + 4
        fcount = fcount + 1
    until( fcount == 100 )	
    gg.loadResults( arm_array )
    arm_array = gg.getResults( 100 )
    for i,v in pairs( arm_array ) do
        table.insert( menu_array, toHexString(arm_array[i].address)..' | '..toHexString( arm_array[i].value ):gsub( "(..)(..)(..)(..)", "%4%3%2%1" )..'r | '..arm_convertor(arm_array[i].value) )
    end
    
    table.insert( menu_array, 'Next 100 Values' )
    
    local h = gg.choice( menu_array,nil, '📜 ARM7 Editor by BadCase 📜\n\nℹ️ Select ARM Instruction To Edit ℹ️' )
    if h ~= nil then
        if h == 100 then
        build_menu( base_address, base_offset, arm_array[h - 1].address )			
        else
        editor_choice( h , arm_array[h].address )
        end
    end	
    --print( arm_array )
end

function editor_choice( k, base_address )
    local reverse_hex = toHexString( arm_array[k].value ):gsub( "(..)(..)(..)(..)", "%4%3%2%1" )
    local h = gg.choice( { '✏️ Edit ARM7: '..menu_array[k]..' ✏️', '📋 Copy ARM7: '..menu_array[k]..' 📋' , '📋 Copy Reverse Hex: '..reverse_hex..' 📋' , '📋 Copy Binary Data: '..dword_to_binary( arm_array[k].value )..' 📋', '📋 Copy DWORD Value: '..arm_array[k].value..' 📋'}, nil, '📜 ARM7 Editor by BadCase 📜\n\n' )
    
    if h == nil then else	
        if h == 1 then
            edit_opcode_menu(arm_array[k].address)
            build_menu( 0, 0, base_address )
        end		
        if h == 2 then
            gg.copyText(menu_array[k])
            build_menu( 0, 0, base_address )
        end
        if h == 3 then
            gg.copyText(reverse_hex)
            build_menu( 0, 0, base_address )
        end
        if h == 4 then
            gg.copyText( dword_to_binary( arm_array[k].value ) )
            build_menu( 0, 0, base_address )
        end
        if h == 5 then
            gg.copyText( arm_array[k].value )
            build_menu( 0, 0, base_address )
        end
    end
end

-------------------------------------------------
-- HEX to ARM GUI
-- End
-------------------------------------------------

-------------------------------------------------
-- ARM to HEX GUI
-- Start
-------------------------------------------------

function edit_or_display( new_hex_opcode, address )
    if type( address ) == 'number' then
        local edit_array = {}
        edit_array[1] = {}
        edit_array[1].address = '0x'..toHexString(address)
        edit_array[1].flags = gg.TYPE_DWORD
        edit_array[1].value = new_hex_opcode..'r'
        gg.setValues( edit_array )
    else
        gg.copyText( new_hex_opcode )
        gg.alert( new_hex_opcode )
    end
end

function edit_opcode_menu(address)
    local reg3_required = false
    local new_hex_opcode = ''
    local edit_opcode_var = ''
    local edit_reg_one_var = ''
    local edit_reg_two_var = ''
    local edit_reg_three_var = ''
    local editor_menu_array = { "🔘 Select OpCode","🔘 Select Register 1","🔘 Select Register 2","🔘 Or Enter Number","🔘 Select Register 3","🔘 Or Enter Number","✅ Done Editing", '❌ Exit' }
    local editor_opcodes_array = { 'MOV', 'MOVW', 'MOVGT', 'ADD', 'SUB', 'CMP', 'MUL', 'LDR', 'LDRB', 'STRB', 'STR', 'VMOV', 'TST', 'EOR', 'NOP', 'BX LR' } 
    local editor_registers_array = { '0000','0001','0010','0011','0100','0101','0110','0111','1000','1001','1010','1011','1100','1101','1110','1111','S0' }
    local editor_reg_display_array = { 'R0','R1','R2','R3','R4','R5','R6','R7','R8','SB','SL','FP','IP','SP','LR','PC' }
    local progress_string = ''
    local progress_opcode = ''
    local progress_reg1 = ''
    local progress_reg2 = ''
    local progress_reg3 = ''
    local progress_bracket_1 = ''
    local progress_bracket_2 = ''	
    ::editing::
    if string.find( progress_opcode, 'STR' ) or string.find( progress_opcode, 'LDR' ) then
        progress_bracket_1 = '['
        progress_bracket_2 = ']'
    else
        progress_bracket_1 = ''
        progress_bracket_2 = ''		
    end
  
    if progress_opcode ~= '' then
        progress_string = progress_opcode
        if progress_reg1 ~= '' then
            progress_string = progress_string..' '..progress_reg1
            if progress_reg2 ~= '' then
                progress_string = progress_string..','..progress_bracket_1..progress_reg2
                if progress_reg3 ~= '' then
                    progress_string = progress_string..','..progress_reg3..progress_bracket_2
                    else
                    progress_string = progress_string..progress_bracket_2
                end
            end
        end
    end
    local h = gg.choice( editor_menu_array, nil, '📜 ARM7 Editor by BadCase 📜\n\nCurrent Edit: '..progress_string )

    if h == nil then 
        goto editing
    else	
        if h == 1 then
            local opcode_menu = gg.choice( editor_opcodes_array , nil, '📜 ARM7 Editor by BadCase 📜\n\n' )

            if opcode_menu == nil then 
                goto editing
            else
                editor_menu_array[1] = editor_opcodes_array[opcode_menu]
                progress_opcode = editor_opcodes_array[opcode_menu]
                edit_opcode_var = editor_opcodes_array[opcode_menu]
                reg3_required = check_if_reg_3_required( edit_opcode_var )
                goto editing
            end
        end
        if h == 2 then
            local reg_one_menu = gg.choice( editor_reg_display_array , nil, '📜 ARM7 Editor by BadCase 📜\n\n' )

            if reg_one_menu == nil then 
                goto editing
            else
                progress_reg1 = editor_reg_display_array[reg_one_menu]
                editor_menu_array[2] = editor_reg_display_array[reg_one_menu]
                edit_reg_one_var = editor_registers_array[reg_one_menu]				
                goto editing
            end		
        end
        if h == 3 then
            local reg_two_menu = gg.choice( editor_reg_display_array , nil, '📜 ARM7 Editor by BadCase 📜\n\n' )

            if reg_two_menu == nil then 
                goto editing
            else
                progress_reg2 = editor_reg_display_array[reg_two_menu]
                editor_menu_array[3] = editor_reg_display_array[reg_two_menu]
                edit_reg_two_var = editor_registers_array[reg_two_menu]				
                goto editing
            end		
        end
        if h == 4 then


            local reg_two_prompt = gg.prompt( { 'ℹ️ Enter Number ℹ️' },{},{ [1]='number' })
            if reg_two_prompt == nil then 
                goto editing
            else
                editor_menu_array[3] = reg_two_prompt[1]
                edit_reg_two_var = tonumber( reg_two_prompt[1] )	
                progress_reg2 = '#'..tonumber( reg_two_prompt[1] )	
                goto editing
            end		
        end			
        if h == 5 then
            local reg_three_menu = gg.choice( editor_reg_display_array , nil, '📜 ARM7 Editor by BadCase 📜\n\n' )			
            if reg_three_menu == nil then 
                goto editing
            else
                progress_reg3 = editor_reg_display_array[reg_three_menu]
                editor_menu_array[4] = editor_reg_display_array[reg_three_menu]
                edit_reg_three_var = editor_registers_array[reg_three_menu]				
                goto editing
            end		
        end		
        if h == 6 then


            local reg_three_prompt = gg.prompt( { 'ℹ️ Enter Number ℹ️' },{},{ [1]='number' })
            if reg_three_prompt == nil then 
                goto editing
            else
                editor_menu_array[5] = reg_three_prompt[1]
                edit_reg_three_var = tonumber( reg_three_prompt[1] )		
                progress_reg3 = '#'..tonumber( reg_three_prompt[1] )	
                goto editing
            end		
        end						
        if h == 7 then
            if edit_opcode_var == 'NOP' or edit_opcode_var == 'BX LR' then
                new_hex_opcode = opcode_generator( edit_opcode_var )
                edit_or_display( new_hex_opcode, address )
            elseif string.find( edit_opcode_var, '.' ) and string.find( edit_reg_one_var, '.' ) and string.find( edit_reg_two_var, '.' ) then
                if reg3_required == true and edit_reg_three_var == '' then
                    gg.alert( 'ℹ️ Set options first ℹ️' )
                    goto editing				
                else
                    if ( reg3_required == true ) or ( reg3_required == false and edit_reg_three_var ~= '' ) then
                        new_hex_opcode = opcode_generator( edit_opcode_var, edit_reg_one_var, edit_reg_two_var, edit_reg_three_var )
                        edit_or_display( new_hex_opcode, address )
                    else
                        new_hex_opcode = opcode_generator( edit_opcode_var, edit_reg_one_var, edit_reg_two_var, false )
                        edit_or_display( new_hex_opcode, address )
                    end
                end		
            else
                gg.alert( 'ℹ️ Set options first ℹ️' )
                goto editing			
            end
        end
        if h == 8 then 
            home() 
        end
    end
end

-------------------------------------------------
-- ARM to HEX GUI
-- End
-------------------------------------------------

function memory_editor()

local check_results = gg.getResults(gg.getResultsCount())
local check_saved = gg.getListItems ()
local results_menu = {}
local saved_menu = {}
if check_results[1] then
    for i,v in ipairs(check_results) do
        table.insert(results_menu, toHexString(check_results[i].address))
    end
end
if check_saved[1] then
    for i,v in ipairs(check_saved) do
        table.insert(saved_menu, toHexString(check_saved[i].address))
    end
end
 local h = gg.choice({'🔘 Enter address to go to','🔘 Go to address from search results', '🔘 Go to address from saved list'},nil, '📜 ARM7 Editor by BadCase 📜\n\nℹ️ Select or Enter Address ℹ️')

    if h == nil then else	
     if h == 1 then
        local h2 = gg.prompt(
        {'ℹ️ Enter Address ℹ️'},
        {},
        {[1]='text'}
        )
        if h2 ~= nil then
            build_menu( h2[1], 0, 0 )
        else 
            home()
        end
    end
    if h == 2 then 
    local h3 = gg.choice(results_menu,nil, '📜 ARM7 Editor by BadCase 📜\n\nℹ️ Select or Enter Address ℹ️')
        if h3 ~= nil then
            build_menu( results_menu[h3], 0, 0 )
        else 
            home()
        end

    end
    if h == 3 then 
    local h4 = gg.choice(saved_menu,nil, '📜 ARM7 Editor by BadCase 📜\n\nℹ️ Select or Enter Address ℹ️')
        if h4 ~= nil then
            build_menu( saved_menu[h4], 0, 0 )
        else 
            home()
        end	end
    end
end

function hex_to_arm()
    local h = gg.prompt( 
        { 'ℹ️ Enter Reverse Hex ℹ️' },
        {},
        { [1]='text' }
    )
    if string.find( h[1], '.' ) then
        decoded_arm = arm_convertor( h[1] )
        gg.copyText( decoded_arm )
        gg.alert( 'ℹ️ '..h[1]..' = '..decoded_arm..' ℹ️' )
    else 
        home()
    end
end

function donate()
    local h = gg.choice( { "🔘 Donate Via PayPal","🔘 Donate Via Gift Card"}, nil, 'Donations can be made via PayPal or via Google Play, PSN or Amazon GiftCards' )
    if h == nil then else	
        if h == 1 then
            gg.copyText('https://www.paypal.me/BadCaseDotOrg')
            gg.alert('ℹ️ Donate via PayPal at https://www.paypal.me/BadCaseDotOrg \nThe link has been copied to your clipboard')
        end
        if h == 2 then
            gg.copyText('https://t.me/BadCaseDotOrg')
            gg.alert('ℹ️ Donate via Google Play, PSN or Amazon Gift Cards by contacting me on my Telegram group https://t.me/BadCaseDotOrg \nThe link has been copied to your clipboard')		
        end
    end
end

function thanks()
gg.alert('ℹ️\nThanks to NoFear for getting me started on understanding ARM\n\nThanks to CmP for teaching me about ARM in further detail and for rewriting some inefficient functions in the script.')
end

function reuse()
gg.alert('You are free to reuse the core encoding and decoding functions of this script so long as it is not in another ARM editor, (if you wish to contribute functions to the editor contact me and you will be given full credit for your contribution) and so long as you give visible credit to me in the GUI of your script such as in an alert triggered by a button labeled "Credits" or something similar.')
end

function home()
    local h = gg.choice( { "✏️ Memory Editor","🔄 Hex to ARM7 Convertor","🔄 ARM7 to Hex Convertor", '💸 Donate', '🙏 Thanks To', 'ℹ️ Reuse of Script Functions', '❌ Exit'}, nil, '📜 ARM7 Editor by BadCase 📜\n\n' )
    
    if h == nil then else	
        if h == 1 then memory_editor() end
        if h == 2 then hex_to_arm() end
        if h == 3 then edit_opcode_menu() end
        if h == 4 then donate() end
        if h == 5 then thanks() end
        if h == 6 then reuse() end
        if h == 7 then os.exit() end
    end
end

while true do
    if gg.isVisible() then
        gg.setVisible( false )
        home()
    end
    gg.sleep( 100 )
end
