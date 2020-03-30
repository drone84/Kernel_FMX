.cpu "65816"
.include "FAT32_def.asm"
.include "SDCard_Controller_def.asm"
.include "stdlib.asm"

* = $10800
FAT32_Byte_Per_Sector           .word 0; 512 for a Floppy disk
FAT32_Sector_Per_Cluster        .word 0; 1
FAT32_Nb_Of_reserved_Cluster    .word 0; 1 , this number include the boot sector
FAT32_Nb_Of_FAT                 .word 0; 2
FAT32_Max_Root_Entry            .word 0; not used in FAT32
FAT32_Total_Sector_Count        .word 0; 2880 => 80 track of 18 sector on each 2 dide (80*18*2)
FAT32_Sector_per_Fat            .dword 0
FAT32_Sector_per_Track          .word 0
FAT32_Nb_of_Head                .word 0
FAT32_Nb_Of_Sector_In_Partition .dword 0
FAT32_Boot_Signature            .word 0
FAT32_Volume_ID                 .dword 0
FAT32_Volume_Label              .fill 11,0 ;0xB
FAT32_File_System_Type          .word 0
FAT32_Sector_loaded_in_ram      .dword 0; updated by any function readding Sector from FDD like : IFAT32_READ_BOOT_SECTOR / IFAT32_COMPUT_ROOT_DIR_POS

FAT32_Root_Sector_offset        .dword 0; hold the ofset in cluster of the first root dirrectory in the fat
FAT32_Root_Base_Sector          .dword 0; hold the first sector containing the Root directory data
FAT32_Curent_Directory_Sector_loaded_in_ram .dword 0  ; store the actual Folder sector loades in ram
FAT32_Curent_Directory_entry_value  .fill 32,0 ; store the 32 byte of root entry
;                                         file Name                                     attribut                                    Cluster High                  Cluster Low  size
FAT32_File_Directory_entry_Template    .text $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,  $00,       $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,     $00,$00,$00,$00 ,$00,$00,     $00,$00,$00,$00; ; store the 32 byte of root entry
FAT32_Folder_Directory_entry_Template  .text $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,  $10,       $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,     $00,$00,$00,$00 ,$00,$00,     $00,$00,$00,$00; ; store the 32 byte of root entry
FAT32_FLN_Directory_entry_Template     .text $40, $20,$00,$20,$00,$20,$00,$20,$00,$20,$00, $0F,      $5A, $20,$00,$20,$00,$20,$00,$20,$00,$20,$00,$20,$00,      $00 ,$00,$00,     $20,$00,$20,$00; ; store the 32 byte of root entry

FAT32_FAT_Base_Sector           .dword 0
FAT32_FAT_Sector_loaded_in_ram  .dword 0  ; store the actual FAT sector loades in ram
FAT32_FAT_Entry                 .dword 0
FAT32_FAT_Next_Entry            .dword 0  ; store the next 32 bit FAT entry associated to the FAT entry in 'FAT32_FAT_Entry'
FAT32_FAT_Linked_Entry          .dword 0

FAT32_FAT_Entry_Physical_Address .dword 0        ; Contain the phisical (from the cluster 0) address of the curent fat entry
FAT32_FAT_Entry_PhisicalL_Address_Next .dword 0   ; Contain the phisical (from the cluster 0) address of the next fat entry

FAT32_Data_Base_Sector          .dword 0  ; contain the sector index of the first data in the FAT volume (that include the reserved cluster after the fat) => used to convert from cluster count to fat index
FAT_Partition_address           .dword 0 ; ofset of the curent FAT volume used

FAT32_Curent_Folder_start_cluster   .dword 0  ; Hold the first cluster of a folder liste from the FAT perspective => real cluster  = FAT32_Curent_Folder_start_cluster + FAT32_Data_Base_Sector
FAT32_Curent_Folder_curent_cluster  .dword 0
FAT32_Folder_Entry_Ofset            .word  0  ; Hold the ofset in the directory where the folder entry is, it's used when updating the file info like size, name, or attribut, work with "FAT32_Curent_Folder_start_cluster"
FAT32_File_Entry_Ofset              .word  0  ; Hold the ofset in the directory where the file entry is, it's used when updating the file info like size, name, or attribut, work with "FAT32_Curent_Folder_start_cluster"
FAT32_Start_Of_The_file_Cluster     .dword 0  ; Hold the first file cluster from the FAT perspective => real cluster  = FAT32_Start_Of_The_file_Cluster + FAT32_Data_Base_Sector
FAT32_Curent_File_Cluster           .dword 0
FAT32_File_Size                     .dword 0

FAT32_Temp_32_bite              .dword 0

FAT32_Sector_to_read            .dword 0
FAT32_SD_FDD_HDD_Sell           .word 0


;------------------------------------------------------------
;file_to_load_fat_32    .text "SDFGVGH TXT"
;file_to_load_fat_32    .text "TEXT_T~1TXT",0
;file_to_load_fat_32    .text "AMIGA   TXT",0
file_to_load_fat_32    .text "HALFLIFEBIN",0
;------------------------------------------------------------
file_to_write_fat_32   .text "TESTFILETXT",0
;------------------------------------------------------------
folder_name_1          .text "DCIM       ",0
folder_name_2          .text "100D3100   ",0

FAT32_counter_32              .dword 0

debug_stop                      .word 0
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------

FAT32_init  ; init
              JSL IFAT32_READ_MBR             ; Init only
              JSL IFAT32_READ_BOOT_SECTOR     ; Init only
              JSL IFAT32_COMPUT_FAT_POS       ; Init only
              JSL IFAT32_COMPUT_ROOT_DIR_POS  ; Init only
              JSL IFAT32_COMPUT_DATA_POS      ; Init only IFAT32_COMPUT_ROOT_DIR_POS need to bew caled before !!!
              ; make sure the FAT sector stored in ram (missing befor init) is differant
              ; than the one we are requesting (at least the first tine the code is called)
              LDA #0
              STA FAT32_Sector_loaded_in_ram
              STA FAT32_Curent_Directory_Sector_loaded_in_ram
              STA FAT32_FAT_Sector_loaded_in_ram
              LDA #0
              STA FAT32_Sector_loaded_in_ram+2
              STA FAT32_Curent_Directory_Sector_loaded_in_ram+2
              STA FAT32_FAT_Sector_loaded_in_ram+2

              ; souldent be nesserarry as IFAT32_GET_ROOT_DIRECTORY_ENTRY is doing it but
              ; for some raison thats not working
              LDA FAT32_Root_Sector_offset
              STA FAT32_Curent_Folder_start_cluster
              LDA FAT32_Root_Sector_offset+2
              STA FAT32_Curent_Folder_start_cluster+2

              JSL IFAT32_GET_ROOT_DIRECTORY_ENTRY
              RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_FAT_Entry_Save                 .dword 0
FAT32_Data_Source_buffer             .dword 0
FAT32_Data_Size                      .dword $800
FAT32_Data_cursor                    .dword $0

FAT32_Open_Creat_Write_File
              LDA #0
              STA FAT32_Data_cursor
              STA FAT32_Data_cursor +2
              LDA #<>Starwars_text
              STA FAT32_Data_Source_buffer
              LDA #`Starwars_text
              STA FAT32_Data_Source_buffer +2
              LDX #0
              setxl
              setas
              LDA #$5A
 LOOP_FILL_BUFFER:
              TXA
              STA @l FAT32_DATA_ADDRESS_BUFFER_512,x ; load the byte nb 3 (bank byte)
              INX
              CPX #$200
              BNE LOOP_FILL_BUFFER
              setaxl
              LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
              PHA
          XBA
          JSL IPRINT_HEX
          XBA
          JSL IPRINT_HEX

              LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
              PHA
          XBA
          JSL IPRINT_HEX
          XBA
          JSL IPRINT_HEX
          LDA #$0D
          JSL IPUTC
              ;LDA FAT32_Sector_to_read
              ;LDX FAT32_Sector_to_read+2
              LDA #5
              LDX #0
              JSL IFAT_WRITE_SECTOR
              LDA #4
              LDX #0
              JSL IFAT_WRITE_SECTOR
              LDA #6
              LDX #0
              JSL IFAT_WRITE_SECTOR
              PLA
              PLA
              ;-------------------------
              JSL FAT32_DIR_CMD
              LDA #$0D
              JSL IPUTC
              ;LDX #$8000      ; 1.6s
              ;JSL ILOOP_MS
              ;-------------------------
              LDA #0
              JSL FAT32_Open_Folder
              JSL FAT32_DIR_CMD
  ;----------------------------------------------------------------------------------------------------
  ;----------------------------------------------------------------------------------------------------
  ;----------------------------------------------------------------------------------------------------
              ; point to the root directory first
              JSL IFAT32_GET_ROOT_DIRECTORY_ENTRY
              JSL FAT32_DIR_CMD ; debug only
              JSL FAT32_Open_File
              CMP #1
              BNE FAT32_Open_Creat_Write_File__search_for_free_entry
              BRL FAT32_Open_Creat_Write_File__File_Opened_with_success
              ;-------------------------
              ; The file to write is not created yet so lets find a free folder
              ; entry to create the file
 FAT32_Open_Creat_Write_File__search_for_free_entry:
              JSL FAT32_Find_Free_Folder_Entry
        PHA
        XBA
        JSL IPRINT_HEX
        XBA
        JSL IPRINT_HEX
        LDA #$0D
        JSL IPUTC
        PLA
              CMP #-1 ; we hit the last cluster whitout finding any free dolder entry
              BEQ FAT32_Open_Creat_Write_File__No_Free_folder_entry
              CMP #-4
              BEQ FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster_temp
              CMP #0
              BNE FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster_temp

              JSL FAT32_Write_Empty_File_Entry
              JSL FAT32_Open_File
              CMP #1
              BNE FAT32_Open_Creat_Write_File__Cant_Open_File_temp
              BEQ FAT32_Open_Creat_Write_File__File_Opened_with_success
 FAT32_Open_Creat_Write_File__Cant_Open_File_temp: BRL FAT32_Open_Creat_Write_File__Cant_Open_File
 FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster_temp: BRL FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster

 FAT32_Open_Creat_Write_File__No_Free_folder_entry:
              ; need to alocate a new sector to the curent folder FAT list
              ; the function is using, "FAT32_FAT_Entry" should contain the
              ; addrerss of the last cluster in the link thanks to "FAT32_Open_File"
              LDA FAT32_FAT_Entry
              STA FAT32_FAT_Entry_Save
              LDA FAT32_FAT_Entry +2
              STA FAT32_FAT_Entry_Save +2
              JSL FAT32_FIND_FREE_FAT_ENTRY
              CMP #1
              BNE FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster_temp
              ;-------------------------
              ; update the nex dat entrey alocated
              LDA FAT32_FAT_Next_Entry
              AND #$F000
              ORA #$0FFF ; last cluster
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE
              LDA #$0FF8 ; last cluster
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE +2
              JSL FAT32_UPDATE_FAT_ENTRY ; set the new alocated FAT entry as the last entry in the list
              ;-------------------------
              ; link the new alocated fat to the old last fat entry
              LDA FAT32_FAT_Entry
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE
              LDA FAT32_FAT_Entry +2
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE +2
              LDA FAT32_FAT_Entry_Save
              STA FAT32_FAT_Entry
              LDA FAT32_FAT_Entry_Save +2
              STA FAT32_FAT_Entry +2
              JSL FAT32_UPDATE_FAT_ENTRY ; point the previous FAT entry to the now allocated FAT entry
              ;-------------------------
              ; Clear the new created cluster
              setas
              LDA #$5A
 LOOP_CLEAR_BUFFER:
              TXA
              STA @l FAT32_DATA_ADDRESS_BUFFER_512,x ; load the byte nb 3 (bank byte)
              INX
              CPX #$200
              BNE LOOP_CLEAR_BUFFER
              setaxl
              ; write the cleared cluster
              LDA FAT32_FAT_Next_Entry +2
              TAX
              LDA FAT32_FAT_Next_Entry
              JSL IFAT_WRITE_SECTOR
              BRL FAT32_Open_Creat_Write_File__search_for_free_entry

 FAT32_Open_Creat_Write_File__File_Opened_with_success: ; test if the file is empty or not
              LDA FAT32_Start_Of_The_file_Cluster
              CMP #0
              BNE FAT32_Open_Creat_Write_File__File_not_empty
              LDA FAT32_Start_Of_The_file_Cluster +2
              CMP #0
              BNE FAT32_Open_Creat_Write_File__File_not_empty
              BRA FAT32_Open_Creat_Write_File__File_empty
 FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster_Temp_2: BRL FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster
 FAT32_Open_Creat_Write_File__File_not_empty:
              JSL IFAT32_Erase_File
 FAT32_Open_Creat_Write_File__File_empty:
              ;-----------------------------------------------------------------
              ; Now we need to write data, as the file is empty we need frirst
              ; to alocate a new cluster to the file and update the file entrt
              ; for the size and first cluster FAT address
              ;-----------------------------------------------------------------
              ; the file is empty so lets find a free FAT entry
              LDA #3 ; skip the root directyory and reserved sector
              STA FAT32_FAT_Entry
              LDA #0
              STA FAT32_FAT_Entry +2
              JSL FAT32_FIND_FREE_FAT_ENTRY
              CMP #1
              BNE FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster_Temp_2
              ;-----------------------------------------------------------------
              ; add the first sector to the newly created file
              ;-----------------------------------------------------------------
              ;save the free cluster found by FAT32_FIND_FREE_FAT_ENTRY
              LDA FAT32_FAT_Next_Entry
              STA FAT32_FAT_Entry_Save
              LDA FAT32_FAT_Next_Entry +2
              STA FAT32_FAT_Entry_Save +2
              ;set the new sector as the last sector
              LDA #$FFF8
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE
              LDA #$FFFF
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE +2
              JSL FAT32_UPDATE_FAT_ENTRY
              ; Read the File entry
              LDA FAT32_File_Entry_Ofset
              JSL IFAT32_GET_DIRECTORY_ENTRY
              ; write the newly alocated cluster in the file entry
              LDA FAT32_FAT_Entry_Save
              STA FAT32_Curent_Directory_entry_value + 26 ;$1A; Low two bytes of first cluster
              LDA FAT32_FAT_Entry_Save +2
              STA FAT32_Curent_Directory_entry_value + 20 ;$14 ; High two bytes of first cluster
              ; Set the sile size to 512 Byte
              LDA #0
              STA FAT32_Curent_Directory_entry_value + 28 ;$1E ; High two bytes of first cluster
              LDA #511
              STA FAT32_Curent_Directory_entry_value + 30 ;$1E ; High two bytes of first cluster
              ; write the data back
              LDA FAT32_File_Entry_Ofset
              JSL FAT32_Write_File_Entry

FAT32_Open_Creat_Write_File__Write_next_cluster:
              ; write the data to the newly alocated cluster
              ; Get the cluster address
              LDA FAT32_FAT_Entry_Save
              STA FAT32_FAT_Entry
              LDA FAT32_FAT_Entry_Save +2
              STA FAT32_FAT_Entry + 2
              ; comput the physycal address
              JSL FAT32_COMPUT_PHISICAL_CLUSTER; (in : FAT32_FAT_Entry / Out : FAT32_FAT_Entry_Physical_Address)
              ; Load the buffer address whare to copy the data from, and where on the disc
              LDA FAT32_Data_Source_buffer +2 ; LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
              PHA
              LDA FAT32_Data_Source_buffer ; LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
              PHA
              LDA FAT32_FAT_Entry_Physical_Address+2
              TAX
              LDA FAT32_FAT_Entry_Physical_Address
              JSL IFAT_WRITE_SECTOR
              PLX
              PLX
              CMP #1
              BEQ  FAT32_Read_File___write_next_Sector
              BRL FAT32_Open_Creat_Write_File__Fail_writing_data
 FAT32_Read_File___write_next_Sector:
              ; incrase the buffer addres by 512
              LDA #$0200
              STA ADDER_A
              LDA #0
              STA ADDER_A+2
              LDA FAT32_Data_Source_buffer
              STA ADDER_B
              LDA FAT32_Data_Source_buffer +2
              STA ADDER_B +2
              LDA ADDER_R
              STA FAT32_Data_Source_buffer
              LDA ADDER_R +2
              STA FAT32_Data_Source_buffer +2

              ; incrase the data cursor addres by 512
              LDA FAT32_Data_cursor
              STA ADDER_B
              LDA FAT32_Data_cursor +2
              STA ADDER_B +2
              LDA ADDER_R
              STA FAT32_Data_cursor
              LDA ADDER_R +2
              STA FAT32_Data_cursor +2

              CMP FAT32_Data_Size+2
              BMI FAT32_Open_Creat_Write_File__END_WRITING
              LDA FAT32_Data_cursor
              CMP FAT32_Data_Size
              BMI FAT32_Open_Creat_Write_File__END_WRITING
              JSL FAT32_FIND_FREE_FAT_ENTRY
              CMP #1
              BNE FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster
              ;-----------------------------------------------------------------
              ; add the first sector to the newly created file
              ;-----------------------------------------------------------------
              ;save the free cluster found by FAT32_FIND_FREE_FAT_ENTRY
              LDA FAT32_FAT_Next_Entry
              STA FAT32_FAT_Entry_Save
              LDA FAT32_FAT_Next_Entry +2
              STA FAT32_FAT_Entry_Save +2
              ;set the new sector as the last sector
              LDA #$FFF8
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE
              LDA #$FFFF
              STA FAT32_FAT_ENTRY_VALUE_TO_WRITE +2
              JSL FAT32_UPDATE_FAT_ENTRY
              BRL FAT32_Open_Creat_Write_File__Write_next_cluster
 FAT32_Open_Creat_Write_File__END_WRITING:
 FAT32_Open_Creat_Write_File__Fail_writing_data:
              fdffggd BRA fdffggd

 FAT32_Open_Creat_Write_File__Cant_Find_Free_Cluster:
              LDA #-1
 FAT32_Open_Creat_Write_File__Cant_Open_File:
              RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------

FAT32_Open_Read_Display_File
              LDA #0
              JSL IFAT32_GET_ROOT_DIRECTORY_ENTRY
              LDA #5
              STA FAT32_FAT_Entry
              LDA #0
              STA FAT32_FAT_Entry+2
              JSL FAT32_IFAT_GET_FAT_ENTRY
          LDA #$0D
          JSL IPUTC
          ;-------------------------
          JSL FAT32_DIR_CMD
          LDA #$0D
          JSL IPUTC
          ;LDX #$8000      ; 1.6s
          ;JSL ILOOP_MS
          ;-------------------------
              ;LDA #`file_to_load_fat_32 ; load the byte nb 3 (bank byte)
              ;PHA
              ;LDA #<>file_to_load_fat_32 ; load the low world part of the buffer address
              ;PHA
              ; set the buffer where to write the data (VRAM)
              LDA #$001B
              STA FAT32_Data_Destination_buffer+2
              LDA #$0000
              STA FAT32_Data_Destination_buffer+0

              JSL FAT32_Open_File
              CMP #1
              BNE FAT32_TEST__Faill_To_Find_file

              ;LDX #0
 loop_read_file:
              JSL FAT32_Read_File
              CMP #0
              BEQ Skip_enpty_data
              PHA
              PHX
              PHY

              ;JSL FAT32_Print_Cluster
              ;JSL FAT32_Print_Cluster_HEX
              JSL FAT32_Copy_Cluster_at_Address
              ;JSL Wait_loop
              ;JSL Wait_loop
              PLY
              PLX
              PLA
 Skip_enpty_data
              ;INX
              ;CPX #19
 ;loop_read_file_freez BEQ loop_read_file_freez
              CMP #1
              BEQ loop_read_file
              ;LDX #$FFFF      ; 1.6s
              ;JSL ILOOP_MS
              ;JSL FAT32_Print_Cluster
              PHX
              PHA
              LDX #<>TEXT__OPEN_FILE_SUCCESS
              LDA #`TEXT__OPEN_FILE_SUCCESS
              JSL IPRINT_ABS
              LDX #<>file_to_load_fat_32
              LDA #`file_to_load_fat_32
              JSL IPRINT_ABS
              ;LDX #$8000      ; 1.6s
              ;JSL ILOOP_MS
              PLA
              PLX
              BRA FAT32_TEST_END

 FAT32_TEST__Faill_To_Find_file:
              PHX
              PHA
              LDX #<>TEXT__CANT_FIND_THE_FILE
              LDA #`TEXT__CANT_FIND_THE_FILE
              JSL IPRINT_ABS
              LDX #<>file_to_load_fat_32
              LDA #`file_to_load_fat_32
              JSL IPRINT_ABS
              ;LDX #$8000      ; 1.6s
              ;JSL ILOOP_MS
              ;LDX #$8000      ; 1.6s
              ;JSL ILOOP_MS
              PLA
              PLX
 FAT32_TEST_END:
              ;-------------------------
              RTL
;-------------------------------------------------------------------------------
;
; display the file name of the 32 first root entry
;
;-------------------------------------------------------------------------------
FAT32_DIR_CMD
                  PHX
                  PHA
 ;----- debug ------
 PHX
 PHA
 LDX #<>TEXT_____DEBUG_START_DIR
 LDA #`TEXT_____DEBUG_START_DIR
 JSL IPRINT_ABS
 PLA
 PLX
 ;-----------------
                  LDX #-1 ; start by readding the first folder entry
 FAT32_DIR_CMD__Read_Next_Folder_Entry:
                  INX
                  TXA ; get the folder entry index
                  CPX #$FFFF ; make sure we are not searching for ever
                  BEQ FAT32_DIR_CMD__EXIT_TEMP
                  BRA FAT32_DIR_CMD_149
 FAT32_DIR_CMD__EXIT_TEMP: BRL FAT32_DIR_CMD__EXIT
 FAT32_DIR_CMD_149:
                  JSL IFAT32_GET_DIRECTORY_ENTRY ; JSL IFAT32_GET_ROOT_DIRECTORY_ENTRY
                  ;;JSL FAT32_PRINT_Root_entry_value_HEX
                  LDA FAT32_Curent_Directory_entry_value +11
                  AND #$00FF
                  CMP #$0F ; test if it's a long name entry
                  BEQ FAT32_DIR_CMD__Read_Next_Folder_Entry
                  AND #$10
                  CMP #$10 ;CMP #$20 ; if different from 0x20 its nor a file name entry (need to confirm that)
                  BEQ FAT32_DIR_CMD__print_folder
                  LDA FAT32_Curent_Directory_entry_value
                  AND #$00FF
                  CMP #$E5 ; test if the entry is deleted
                  BEQ FAT32_DIR_CMD__Read_Next_Folder_Entry
                  CMP #$00 ; test if we reached the last entry in the folder
                  BEQ FAT32_DIR_CMD__EXIT_TEMP_2
                  BRA FAT32_DIR_CMD_168
 FAT32_DIR_CMD__EXIT_TEMP_2: BRL FAT32_DIR_CMD__EXIT
 FAT32_DIR_CMD_168:
                  LDA #0
                  ;STA @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
                  STA FAT32_LONG_FILE_NAME_BUFFER_pointer
                  TXA ; get the folder entry index
                  JSL IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME

                  PHA
                  LDA #$2D                  ; Set the default text color to light gray on dark gray
                  JSL SET_COLOUR
                  LDA #$0D
                  JSL IPUTC
                  PLA

                  CMP #1
                  BEQ FAT32_DIR_CMD__Print_FLN_File_Name
                  ;------ print the short name -----
                  JSL FAT32_Print_File_Name
                  LDA #$0D
                  JSL IPUTC
                  LDA #$ED                  ; Set the default text color to light gray on dark gray
                  JSL SET_COLOUR
                  BRL FAT32_DIR_CMD__Read_Next_Folder_Entry
 FAT32_DIR_CMD__Print_FLN_File_Name:
                  ;------ print the Long Name -----
                  PHX
                  PHA
                  LDX #<>FAT32_LONG_FILE_NAME_BUFFER_256
                  LDA #`FAT32_LONG_FILE_NAME_BUFFER_256
                  JSL IPUTS_ABS
                  LDA #$0D
                  JSL IPUTC
                  LDA #$ED                  ; Set the default text color to light gray on dark gray
                  JSL SET_COLOUR
                  PLA
                  PLX
                  BRL FAT32_DIR_CMD__Read_Next_Folder_Entry

 FAT32_DIR_CMD__print_folder:
                  LDA #0
                  ;STA @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
                  STA FAT32_LONG_FILE_NAME_BUFFER_pointer
                  TXA ; get the folder entry index
                  JSL IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME
                  PHA ; save the FLN result
                  LDA #$8D                  ; Set the default text color to light gray on dark gray
                  JSL SET_COLOUR
                  LDA #$0D
                  JSL IPUTC
                  PLA

                  CMP #1
                  BEQ FAT32_DIR_CMD__Print_FLN_Folder_Name
                  ;------ print the short name -----
                  PHA ; save the FLN result
                  JSL FAT32_Print_Folder_Name
                  LDA #$0D
                  JSL IPUTC
                  LDA #$ED                  ; Set the default text color to light gray on dark gray
                  JSL SET_COLOUR
                  PLA
                  BRL FAT32_DIR_CMD__Read_Next_Folder_Entry
 FAT32_DIR_CMD__Print_FLN_Folder_Name:
                  ;------ print the Long Name -----
                  PHX
                  PHA
                  LDX #<>FAT32_LONG_FILE_NAME_BUFFER_256
                  LDA #`FAT32_LONG_FILE_NAME_BUFFER_256
                  JSL IPUTS_ABS
                  LDA #$0D
                  JSL IPUTC
                  LDA #$ED                  ; Set the default text color to light gray on dark gray
                  JSL SET_COLOUR
                  PLA
                  PLX
                  BRL FAT32_DIR_CMD__Read_Next_Folder_Entry
 FAT32_DIR_CMD__EXIT:
 ;----- debug ------
 PHX
 PHA
 LDX #<>TEXT_____DEBUG_END_DIR
 LDA #`TEXT_____DEBUG_END_DIR
 JSL IPRINT_ABS
 PLA
 PLX
 ;-----------------
                  PLA
                  PLX
                  RTL

;-------------------------------------------------------------------------------
; Search for a free folder entry (not used 0x00 or deleted 0xE5)
; In
; A
; folder index to start searching from
;
; return
; A
; xxxx => folder entry index sellected
; -1  =>  end of the file, no more sector
; -2  =>  bad sector
; -3  =>  reserved sector
; -4  => can't find any free folder entry
;-------------------------------------------------------------------------------
FAT32_Find_Free_Folder_Entry_From_Index
                  setaxl
                  PHX
                  TAX
                  BRA FAT32_Find_Free_Folder_Entry__Read_Next_Folder_Entry
FAT32_Find_Free_Folder_Entry
                  setaxl
                  PHX
                  LDX #0 ; start by readding the first folder entry

 ;----- debug ------
 PHX
 PHA
 LDX #<>TEXT_____DEBUG_START_Find_Free_Folder_Entry
 LDA #`TEXT_____DEBUG_START_Find_Free_Folder_Entry
 JSL IPRINT_ABS
 PLA
 PLX
  ;-----------------

 FAT32_Find_Free_Folder_Entry__Read_Next_Folder_Entry:
                  TXA
                  CPX #$FFFF ; make sure we are not searching for ever
                  BEQ FAT32_Find_Free_Folder_Entry__EXIT_TOO_MANY_FOLDER_ENTRY
                  JSL IFAT32_GET_DIRECTORY_ENTRY
                  CMP #1
                  BNE FAT32_Find_Free_Folder_Entry__EXIT
                  ;JSL FAT32_PRINT_Root_entry_value ;_HEX
                  JSL FAT32_GET_FOLDER_ENTRY_TYPE
                  CMP #$E5 ; deleted folder entry
                  BEQ FAT32_Find_Free_Folder_Entry__FIND_A_FILE_ENTRY
                  CMP #$00 ; new empty folder entry
                  BEQ FAT32_Find_Free_Folder_Entry__FIND_A_FILE_ENTRY
                  INC X
                  BRA FAT32_Find_Free_Folder_Entry__Read_Next_Folder_Entry
 FAT32_Find_Free_Folder_Entry__FIND_A_FILE_ENTRY:
                  ;-------------------------------------------------------------
                  TXA
                  BRA FAT32_Find_Free_Folder_Entry__EXIT
 FAT32_Find_Free_Folder_Entry__EXIT_TOO_MANY_FOLDER_ENTRY:
                  LDA #-4
 FAT32_Find_Free_Folder_Entry__EXIT:
  ;----- debug ------
  PHX
  PHA
  LDX #<>TEXT_____DEBUG_END_Find_Free_Folder_Entry
  LDA #`TEXT_____DEBUG_END_Find_Free_Folder_Entry
  JSL IPRINT_ABS
  PLA
  PLX
  ;-----------------
                  PLX
                  RTL

;-------------------------------------------------------------------------------
; write at the A location an enpty file tamplate with the file name from
; file_to_write_fat_32
; In
; A :
; folder index to write the new file into
;
; file_to_write_fat_32 :
; file name
;
; return
; A
;-------------------------------------------------------------------------------
FAT32_Write_Empty_File_Entry
                  setaxl
  ;----- debug ------
  PHX
  PHA
  LDX #<>TEXT_____DEBUG_START_Write_File_Directory_entry
  LDA #`TEXT_____DEBUG_START_Write_File_Directory_entry
  JSL IPRINT_ABS
  PLA
  PLX
  ;-----------------
                  PHA
        ;JSL FAT32_PRINT_Root_entry_value_HEX
                  ;-------------------------------------------------------------
                  ; Write the blank file directory tamplate
                  LDA #<>FAT32_File_Directory_entry_Template
                  TAX
                  LDA #<>FAT32_Curent_Directory_entry_value
                  TAY
                  LDA #31
                  MVN `FAT32_File_Directory_entry_Template, `FAT32_Curent_Directory_entry_value
        ;JSL FAT32_PRINT_Root_entry_value_HEX
        ;JSL FAT32_PRINT_Root_entry_value
                  ;-------------------------------------------------------------
                  ; Write the file name
                  LDA #<>file_to_write_fat_32
                  TAX
                  LDA #<>FAT32_Curent_Directory_entry_value
                  TAY
                  LDA #11
                  MVN `file_to_write_fat_32, `FAT32_Curent_Directory_entry_value
        ;JSL FAT32_PRINT_Root_entry_value_HEX
        ;JSL FAT32_PRINT_Root_entry_value
        ;JSL FAT32_Print_Directory_Cluster_HEX
FAT32_Write_File_Entry
                  ;-------------------------------------------------------------
                  ; comput the ofset in the curent directory sector loaded
                  ; in ram to write the 32 Byte
                  LDA #<>FAT32_Curent_Directory_entry_value
                  TAX
                  PLA
                  AND #$000F ; get only the 4 first bit as we assune theat the sectore in ram is the one sector to write the data in (loaded by FAT32_Find_Free_Folder_Entry normaly)
                  ASL
                  ASL
                  ASL
                  ASL
                  ASL ; now A contain the ofset to write the root entry
                  CLC
                  ADC #<>FAT32_FOLDER_ADDRESS_BUFFER_512
                  TAY
                  LDA #31
                  MVN `FAT32_Curent_Directory_entry_value, `FAT32_FOLDER_ADDRESS_BUFFER_512
        ;JSL FAT32_Print_Directory_Cluster_HEX
                  ;-------------------------------------------------------------
                  ; write back the new data
                  LDA #`FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Curent_Directory_Sector_loaded_in_ram+2
                  TAX
                  LDA FAT32_Curent_Directory_Sector_loaded_in_ram
                  JSL IFAT_WRITE_SECTOR
  ;----- debug ------
  PHX
  PHA
  LDX #<>TEXT_____DEBUG_END_Write_File_Directory_entry
  LDA #`TEXT_____DEBUG_END_Write_File_Directory_entry
  JSL IPRINT_ABS
  PLA
  PLX
  ;-----------------
                  RTL
;-------------------------------------------------------------------------------
; Search for the file name in the root directory
; File name to oppen : file_to_load_fat_32
; return
; A
; 1 -> file open with success
; 0 -> reach the end of the folder entry without matching the file name
;-1 -> went thrw to many folder entry (more than 65535) so exit
;
; FOR NOW THE CURENT DIRECTORY IS THE ROOT DIRECTORY
;-------------------------------------------------------------------------------
FAT32_Open_File
                  setaxl
                  LDX #0 ; start by readding the first folder entry

 ;----- debug ------
 PHX
 PHA
 LDX #<>TEXT_____DEBUG_START_Open
 LDA #`TEXT_____DEBUG_START_Open
 JSL IPRINT_ABS
 PLA
 PLX
  ;-----------------

 FAT32_Open_File_Read_Next_Folder_Entry:
                  TXA
                  CPX #$FFFF ; make sure we are not searching for ever
                  BEQ FAT32_Open_File__EXIT_TOO_MANY_FOLDER_ENTRY_temp
                  JSL IFAT32_GET_DIRECTORY_ENTRY
                  CMP #1
                  BNE FAT32_Open_File__EXIT_temp
                  INC X
                  JSL FAT32_GET_FOLDER_ENTRY_TYPE
                  CMP #1
                  BEQ FAT32_Open_File__FIND_A_FILE_ENTRY
                  CMP #0
                  BEQ FAT32_Open_File__EXIT_END_OF_THE_ENTRY_LISTE
                  BRA FAT32_Open_File_Read_Next_Folder_Entry
 FAT32_Open_File__EXIT_TOO_MANY_FOLDER_ENTRY_temp: BRL FAT32_Open_File__EXIT_TOO_MANY_FOLDER_ENTRY
 FAT32_Open_File__EXIT_temp: BRL FAT32_Open_File__EXIT
 FAT32_Open_File__FIND_A_FILE_ENTRY:
                  ;-------------------------------------------------------------
                  ; compare the file name we want to load and the folder entry file name
                  JSL FAT32_Print_File_Name
                  LDA #$0D
                  JSL IPUTC
                  PHX
                  LDX #-1 ; to get x = 0 on the first loop
                  setas
 FAT32_Open_File__CHAR_MATCHING:
                  INC X
                  CPX #11 ; FAT12 file or folder size
                  BEQ FAT32_Open_File__STRING_MATCHED
                  setas
                  ;LDA FAT32_Curent_Directory_entry_value,X for the bebugger
                  LDA file_to_load_fat_32,X
                  CMP FAT32_Curent_Directory_entry_value,X
                  BEQ FAT32_Open_File__CHAR_MATCHING ; if the file name match  the loop will be executed 11 time
                  PLX
                  setal
                  BRL FAT32_Open_File_Read_Next_Folder_Entry ; the name dosn't match
                  ;-------------------------------------------------------------
                  ; We find the file name
 FAT32_Open_File__STRING_MATCHED:
                  PLA ; removing the ofset from the stack
                  STA FAT32_File_Entry_Ofset
                  setaxl
                  JSL FAT32_PRINT_Root_entry_value_HEX ; Debug
                  ; Update the first cluster location
                  LDA FAT32_Curent_Directory_entry_value + 26 ;$1S; Low two bytes of first cluster
                  STA FAT32_Start_Of_The_file_Cluster
                  LDA FAT32_Curent_Directory_entry_value + 20 ;$14 ; High two bytes of first cluster
                  STA FAT32_Start_Of_The_file_Cluster + 2
                  ; Update the file size
                  LDA FAT32_Curent_Directory_entry_value + 28 ;$1E ; High two bytes of the file size
                  STA  FAT32_File_Size
                  STA FAT32_Curent_Directory_entry_value + 30 ;$1E ; Low two bytes of the file size
                  STA  FAT32_File_Size +2

                  LDA #0 ; FAT32_Curent_File_Cluster = 0 to indicat to the read code to read from the beginning
                  STA FAT32_Curent_File_Cluster
                  STA FAT32_Curent_File_Cluster + 2
                  LDA #1 ; return success
                  BRA FAT32_Open_File__EXIT
 FAT32_Open_File__EXIT_END_OF_THE_ENTRY_LISTE:
                  LDA #0
                  BRA FAT32_Open_File__EXIT
 FAT32_Open_File__EXIT_TOO_MANY_FOLDER_ENTRY:
                  LDA #-4
 FAT32_Open_File__EXIT:
  ;----- debug -----
  PHX
  PHA
  LDX #<>TEXT_FAT32___FAT32_Start_Of_The_file_Cluster
  LDA #`TEXT_FAT32___FAT32_Start_Of_The_file_Cluster
  JSL IPUTS_ABS       ; print the first line
  LDA #$BD
  JSL SET_COLOUR
  LDA FAT32_Start_Of_The_file_Cluster+2
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA FAT32_Start_Of_The_file_Cluster
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$ED                  ; Set the default text color to light gray on dark gray
  JSL SET_COLOUR

  LDA #$0D
  JSL IPUTC
  PLA
  PLX
  ;--------------------------
  ;----- debug ------
  PHX
  PHA
  LDX #<>TEXT_____DEBUG_END_Open
  LDA #`TEXT_____DEBUG_END_Open
  JSL IPRINT_ABS
  PLA
  PLX
  ;-----------------
                  RTL

;-------------------------------------------------------------------------------
; Search for the folder name in the root directory
; Folder name to oppen : folder_name_1
; return
; A
; 1 -> folder open with success
; 0 -> reach the end of the folder entry withut matching the folder name
;-1 -> went thrw to many folder entry (more than 65535) so exit
;
;
;-------------------------------------------------------------------------------
FAT32_Open_Folder
                  setaxl
                  LDX #0 ; start by readding the first folder entry
 ;----- debug ------
 PHX
 PHA
 LDX #<>TEXT_____DEBUG_START_Open
 LDA #`TEXT_____DEBUG_START_Open
 JSL IPRINT_ABS
 PLA
 PLX
  ;-----------------

 FAT32_Open_Folder_Read_Next_Folder_Entry:
                  TXA
                  CPX #$FFFF ; make sure we are not searching for ever
                  BEQ FAT32_Open_Folder__EXIT_TOO_MANY_FOLDER_ENTRY_1
                  JSL IFAT32_GET_DIRECTORY_ENTRY ; JSL IFAT32_GET_ROOT_DIRECTORY_ENTRY
                  CMP #1
                  BNE FAT32_Open_Folder__EXIT
                  INC X
                  JSL FAT32_GET_FOLDER_ENTRY_TYPE
  .comment
  PHX
  PHA
  BRA _TEST_TEXT_229
  _text_229 .text "---- Folder entry type ",0
  _TEST_TEXT_229:
  LDX #<>_text_229
  LDA #`_text_229
  JSL IPUTS_ABS
  PLA
  PHA
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$0D
  JSL IPUTC
  ;LDX #$8000      ; 1.6s
  ;JSL ILOOP_MS
  ;-------------------------
  PLA
  PLX
  .endc
                  CMP #$10 ; folder entry type
                  BEQ FAT32_Open_Folder__FIND_A_FOLDER_ENTRY
                  CMP #0
                  BEQ FAT32_Open_Folder__EXIT_END_OF_THE_ENTRY_LISTE
                  BRA FAT32_Open_Folder_Read_Next_Folder_Entry
 FAT32_Open_Folder__EXIT_TOO_MANY_FOLDER_ENTRY_1: BRA  FAT32_Open_Folder__EXIT_TOO_MANY_FOLDER_ENTRY
 FAT32_Open_Folder__FIND_A_FOLDER_ENTRY:
                  ;-------------------------------------------------------------
                  ; compare the file name we want to load and the folder entry file name
                  JSL FAT32_Print_Folder_Name
                  LDA #$0D
                  JSL IPUTC
                  PHX
                  LDX #-1 ; to get x = 0 on the first loop
                  setas
 FAT32_Open_Folder__CHAR_MATCHING:
                  INC X
                  CPX #11 ; FAT12 file or folder size
                  BEQ FAT32_Open_Folder__STRING_MATCHED
                  setas
                  ;LDA FAT32_Curent_Directory_entry_value,X for the bebugger
                  LDA folder_name_1,X
                  CMP FAT32_Curent_Directory_entry_value,X
                  BEQ FAT32_Open_Folder__CHAR_MATCHING ; if the file name match  the loop will be executed 11 time
                  PLX
                  setal
                  BRL FAT32_Open_Folder_Read_Next_Folder_Entry ; the name dosn't match
                  ;-------------------------------------------------------------
                  ; We find the file name
 FAT32_Open_Folder__STRING_MATCHED:
                  PLA ; removing the ofset from the stack
                  STA FAT32_Folder_Entry_Ofset
                  setaxl
                  JSL FAT32_PRINT_Root_entry_value_HEX ; Debug
                  LDA FAT32_Curent_Directory_entry_value + 26 ;$1S; Low two bytes of first cluster
                  STA FAT32_Curent_Folder_start_cluster
                  LDA FAT32_Curent_Directory_entry_value + 20 ;$14 ; High two bytes of first cluster
                  STA FAT32_Curent_Folder_start_cluster + 2
                  LDA #0 ; FAT32_Curent_File_Cluster = 0 to indicat to the read code to read from the beginning
                  STA FAT32_Curent_File_Cluster
                  STA FAT32_Curent_File_Cluster + 2
                  LDA #1 ; return success
                  BRA FAT32_Open_Folder__EXIT
 FAT32_Open_Folder__EXIT_END_OF_THE_ENTRY_LISTE:
                  LDA #0
                  BRA FAT32_Open_Folder__EXIT
 FAT32_Open_Folder__EXIT_TOO_MANY_FOLDER_ENTRY:
                  LDA #-1
 FAT32_Open_Folder__EXIT:
  ;----- debug -----
  PHX
  PHA
  LDX #<>TEXT_FAT32___FAT32_Start_Of_The_folder_Cluster
  LDA #`TEXT_FAT32___FAT32_Start_Of_The_folder_Cluster
  JSL IPUTS_ABS       ; print the first line
  LDA #$BD
  JSL SET_COLOUR
  LDA FAT32_Curent_Folder_start_cluster+2
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA FAT32_Curent_Folder_start_cluster
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$ED                  ; Set the default text color to light gray on dark gray
  JSL SET_COLOUR

  LDA #$0D
  JSL IPUTC
  PLA
  PLX
  ;--------------------------
  ;----- debug ------
  PHX
  PHA
  LDX #<>TEXT_____DEBUG_END_Open
  LDA #`TEXT_____DEBUG_END_Open
  JSL IPRINT_ABS
  PLA
  PLX
  ;-----------------
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_Read_File   ;  return value in A
                  PHX
  ;----- debug ------
  ;PHX
  ;PHA
  ;LDX #<>TEXT_____DEBUG_START_Read
  ;LDA #`TEXT_____DEBUG_START_Read
  ;JSL IPRINT_ABS
  ;PLA
  ;PLX
  ;-----------------
                  ; test if the file have already bin read
                  LDA FAT32_Curent_File_Cluster
                  CMP #0
                  BNE FAT32_Read_File___Get_Next_Sector
                  LDA FAT32_Curent_File_Cluster+2
                  CMP #0
                  BNE FAT32_Read_File___Get_Next_Sector
                  ; If FAT32_Read_File___Get_Next_Sector == 0 , it mean that the file havent bin read yet so initialise curent fat entry
                  LDA FAT32_Start_Of_The_file_Cluster ; sector of the begening of the file
                  STA FAT32_Curent_File_Cluster
                  LDA FAT32_Start_Of_The_file_Cluster+2
                  STA FAT32_Curent_File_Cluster+2

 FAT32_Read_File___Get_Next_Sector:
                  ; Get the curent sector to read
                  LDA FAT32_Curent_File_Cluster
                  STA FAT32_FAT_Entry
                  LDA FAT32_Curent_File_Cluster+2
                  STA FAT32_FAT_Entry+2
                  ; test if we can read the curent cluster and if its the last cluster in the chine
                  JSL FAT32_Test_Fat_Entry_Validity
                  CMP #1
                  BEQ FAT32_Read_File__Valit_sector
                  CMP #-1
                  BEQ FAT32_Read_File___End_OF_File
                  BRL FAT32_Read_File___Reserved_Or_Bad_Sector
 FAT32_Read_File__Valit_sector:
                  ;LDA #1 ; sector still avaliable return value
                  PHA ; save the return value
                  ; The curent entry is not the last one so get the next fat
                  ; entry to update the curent fat entry at the end of the function
                  JSL FAT32_IFAT_GET_FAT_ENTRY ; get the next sector
                  BRA FAT32_Read_File___still_several_sector_to_read
 FAT32_Read_File___End_OF_File:
                  LDA #0  ; EOF return value
                  PHA ; save the return value
 FAT32_Read_File___still_several_sector_to_read:

                  ; if everyting is ok (last sector or in the middle of the file)
                  ; then read the data
                  JSL FAT32_COMPUT_PHISICAL_CLUSTER; (in : FAT32_FAT_Entry / Out : FAT32_FAT_Entry_Physical_Address)

                  ;JSL FAT32_Print_FAT_ENTRY_INFO

                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Entry_Physical_Address+2
                  TAX
                  LDA FAT32_FAT_Entry_Physical_Address
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX
                  CMP #1
                  BEQ  FAT32_Read_File___Read_Sector
                  ;           FAT32_Read_File___Error_while_readding_sector:
                  PLA       ; remode the saved pres saved return value
                  LDA #-4   ; load the error reading sector error
 FAT32_Read_File___Reserved_Or_Bad_Sector:
                  BRL FAT32_Read_File___RETURN_ERROR
 FAT32_Read_File___Read_Sector:
                  ; Update the FAT index for the next round
                  LDA FAT32_FAT_Next_Entry ;
                  STA FAT32_Curent_File_Cluster
                  LDA FAT32_FAT_Next_Entry+2
                  STA FAT32_Curent_File_Cluster+2
                  PLA ; Get the return value in A

 FAT32_Read_File___RETURN_ERROR:
  ;----- debug ------
  ;PHX
  ;PHA
  ;LDX #<>TEXT_____DEBUG_END_Read
  ;LDA #`TEXT_____DEBUG_END_Read
  ;JSL IPRINT_ABS
  ;PLA
  ;PLX
  ;-----------------
                  PLX
                  RTL
;
;-------------------------------------------------------------------------------
;
; The file need to be opened before erasing as, oppening it setup all the address
; For now it's only erasing the fat entry, not the data in the cluster
; IN :
; - FAT32_FAT_Entry FAT entry where to start the linked readding
;
; return value :
;  1  =>  erase successful
; -1  =>  bad fat entry
;-------------------------------------------------------------------------------
IFAT32_Erase_File
                  PHX
 IFAT32_ERASE_FILE___READ_NEXT_FAT:
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  ;-------------------------------------------------------------
                  ; test the fat entry for reserved or bad sector
                  JSL FAT32_Test_Fat_Entry_Validity_Next
                  CMP #1
                  BEQ IFAT32_ERASE_FILE___NEXT_VALID_CLUSTER
                  CMP #-1
                  BNE IFAT32_ERASE_FILE___EXIT
                  JSL FAT32_CLEAR_FAT_ENTRY
                  ;LDA #1
                  ;BRL IFAT32_ERASE_FILE___EXIT
                  BRL IFAT32_ERASE_FILE___ALL_LINKED_FAT_PARSED__UPDATE_FILE_ENTRY
                  ;-------------------------------------------------------------

                  ; the fat entry is containning data, now decrementing the
                  ; linked counter  to see if we need to look at the next fat entry
 IFAT32_ERASE_FILE___NEXT_VALID_CLUSTER:
                  ; erase the curent fat entry value
                  JSL FAT32_CLEAR_FAT_ENTRY
                  ;;;JSL IFAT32_DEC_FAT_Linked_Entry
                  ;;;LDA FAT32_FAT_Linked_Entry
                  ;;;CMP #0
                  ;;;BEQ IFAT32_ERASE_FILE___TEST_HIGH_PART
                  ; update the next fat entry to read
                  LDA FAT32_FAT_Next_Entry
                  STA FAT32_FAT_Entry
                  LDA FAT32_FAT_Next_Entry+2
                  STA FAT32_FAT_Entry+2
                  BRL IFAT32_ERASE_FILE___READ_NEXT_FAT
 ;;;IFAT32_ERASE_FILE___TEST_HIGH_PART:
                  ;;;LDA FAT32_FAT_Linked_Entry+2
                  ;;;CMP #0
                  ;;;BEQ IFAT32_ERASE_FILE___ALL_LINKED_FAT_PARSED
                  ;;;LDA FAT32_FAT_Next_Entry
                  ;;;STA FAT32_FAT_Entry
                  ;;;LDA FAT32_FAT_Next_Entry+2
                  ;;;STA FAT32_FAT_Entry+2
                  ;;;BRL IFAT32_ERASE_FILE___READ_NEXT_FAT
 IFAT32_ERASE_FILE___ALL_LINKED_FAT_PARSED__UPDATE_FILE_ENTRY:

                  ;-------------------------------------------------------------
                  ; Read the File entry
                  LDA FAT32_File_Entry_Ofset
                  JSL IFAT32_GET_DIRECTORY_ENTRY
                  ; Cleas alocated cluster in the file entry
                  LDA #0
                  STA FAT32_Curent_Directory_entry_value + 26 ;$1A; Low two bytes of first cluster
                  STA FAT32_Curent_Directory_entry_value + 20 ;$14 ; High two bytes of first cluster
                  ;  Set the file size to 0 Byte
                  LDA #0
                  STA FAT32_Curent_Directory_entry_value + 28 ;$1E ; High two bytes of the file size
                  STA FAT32_Curent_Directory_entry_value + 30 ;$1E ; Low two bytes of the file size
                  ; Write the data back
                  LDA FAT32_File_Entry_Ofset
                  JSL FAT32_Write_File_Entry
                  ;-------------------------------------------------------------#
                  LDA #0
                  STA FAT32_Start_Of_The_file_Cluster
                  STA FAT32_Start_Of_The_file_Cluster +2
                  LDA #1
 IFAT32_ERASE_FILE___EXIT:
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
; Read the Master Boot Record to get the address of the first FAT32 partition
;
;
;-------------------------------------------------------------------------------
IFAT32_READ_MBR   setal
                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA #0 ; read sector 0 (where the MBR sector is stored)
                  LDX #0
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX

                  LDX #MBR_Partition_Entry
 READ_MBR_Scan:
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X+8
                  CMP #0
                  BEQ READ_MBR_Partition_Entry_LSB_Null
                  LDY #1
 READ_MBR_Partition_Entry_LSB_Null:
                  STA FAT_Partition_address
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X+8+2
                  CMP #0
                  BEQ READ_MBR_Partition_Entry_MSB_Null
                  LDY #1
 READ_MBR_Partition_Entry_MSB_Null:
                  STA FAT_Partition_address+2

                  CPY #1 ; curent MBR entry not nul (sector location)
                  BEQ READ_MBR_Partition_valid_address
                  CPX #$1FE
                  BEQ READ_MBR_End_Scan_no_partition
                  TXA ; Conput the next NBR entry position
                  ADC #MBR_Partition_Entry_size
                  TAX
                  BRA READ_MBR_Scan

 READ_MBR_Partition_valid_address: ; the number in FAT_Partition_address is an ofset in cluster of a Partiton
                  LDX #<>Partition_ofset_text
                  LDA #`Partition_ofset_text
                  JSL IPUTS_ABS       ; print the first line
                  LDA #'0'
                  JSL IPUTC
                  LDA #'x'
                  JSL IPUTC
                  LDA FAT_Partition_address +3
                  JSL IPRINT_HEX
                  LDA FAT_Partition_address +2
                  JSL IPRINT_HEX
                  LDA FAT_Partition_address +1
                  JSL IPRINT_HEX
                  LDA FAT_Partition_address
                  JSL IPRINT_HEX
                  LDA #$0D
                  JSL IPUTC
                  LDA #1 ; success
                  BRA READ_MBR_End
                  ;-----------------------------------
                  ;LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  ;PHA
                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  ;PHA
                  ;LDA FAT_Partition_address+2 ; dont use X value for now IFAT_READ_SECTOR is a dummy function unlit I ger the real HDD hardware driver
                  ;TAX
                  ;LDA FAT_Partition_address
                  ;LDX FAT32_Sector_to_read+2
                  ;JSL IFAT_READ_SECTOR

 READ_MBR_End_Scan_no_partition:
                  LDA #-1
 READ_MBR_End:
                  RTL
;-------------------------------------------------------------------------------
;
; Read the Boot Sector to get all the information about the FAT32 partition
; like the size, root directory location, FAT tabel location etc
;
;-------------------------------------------------------------------------------
IFAT32_READ_BOOT_SECTOR
                  setaxl
                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT_Partition_address+2 ; dont use X value for now IFAT_READ_SECTOR is a dummy function unlit I ger the real HDD hardware driver
                  TAX
                  LDA FAT_Partition_address
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX;
                  STA FAT32_Sector_loaded_in_ram
                   ; Byte per sector offset ; 2 byte data
                  LDX #$B ;11
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Byte_Per_Sector

                  LDX #$0D ;13
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  AND #$FF
                  STA FAT32_Sector_Per_Cluster

                  LDX #$0E ;14
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_Of_reserved_Cluster

                  LDX #$10 ;16
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  AND #$FF
                  STA FAT32_Nb_Of_FAT

                  LDX #$18 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Track

                  LDX #$1A ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_of_Head

                  LDX #$20 ;36 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_Of_Sector_In_Partition
                  LDX #$22 ;36 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_Of_Sector_In_Partition+2

                  LDX #$24 ;36 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Fat
                  LDX #$26 ;36 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Fat+2

                  LDX #$2C ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Root_Sector_offset
                  LDX #$2E ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Root_Sector_offset+2
                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512
                  ;ADC #43
                  ;TAX
                  ;LDY #<>Volume_Label
                  ;LDA #11-1
                  ;MVN `FAT32_Volume_Label , `FAT32_DATA_ADDRESS_BUFFER_512

                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512
                  ;ADC #54
                  ;TAX
                  ;LDY #<>File_System_Type
                  ;LDA #8-1
                  ;MVN `FAT32_File_System_Type, `FAT32_DATA_ADDRESS_BUFFER_512


                  ; at this point all the important FAT infornation are stored between 19000 and 19030
                  LDA FAT32_Byte_Per_Sector
                  CMP #512
                  BNE FAT32_ERROR_BLOCK_SEIZE

                  LDA FAT32_Sector_Per_Cluster
                  CMP #1
                  BNE FAT32_ERROR_SECTOR_PER_CLUSTER

                  LDA FAT32_Nb_Of_reserved_Cluster
                  CMP #1
                  BCC FAT32_ERROR_RESERVED_SECTOR

                  LDA FAT32_Nb_Of_FAT
                  CMP #1
                  BCC FAT32_ERROR_NB_FAT

                  ;LDA FAT32_Max_Root_Entry
                  ;cMP #224
                  ;BNE FAT32_ERROR_NB_ROOT_ENTRY

                  ;LDA FAT32_Total_Sector_Count
                  ;CMP #2880
                  ;BNE FAT32_ERROR_NB_TOTAL_SECTOR_COUNT

                  LDA FAT32_Sector_per_Fat
                  CMP #0
                  BEQ FAT32_ERROR_SECTOR_PER_FAT
                  LDA FAT32_Sector_per_Fat+2
                  CMP #0
                  BEQ FAT32_ERROR_SECTOR_PER_FAT

                  LDA FAT32_Root_Sector_offset
                  CMP #2
                  BCC FAT32_ERROR_FAT_SECTOR_OFFSET
                  LDA FAT32_Root_Sector_offset+2
                  CMP #0
                  BCC FAT32_ERROR_FAT_SECTOR_OFFSET
                  ;LDA FAT32_Boot_Signature
                  ;CMP #$29
                  ;BNE FAT32_ERROR_BOOT_SIGNATURE
                  LDA #1
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_BLOCK_SEIZE LDA #-1
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_SECTOR_PER_CLUSTER
                  LDA #-2
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_RESERVED_SECTOR
                  LDA #-3
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_NB_FAT      LDA #-4
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_NB_ROOT_ENTRY
                  LDA #-5
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_NB_TOTAL_SECTOR_COUNT
                  LDA #-6
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_SECTOR_PER_FAT
                  LDA #-7
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_FAT_SECTOR_OFFSET
                  LDA #-11
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_SECTOR_PER_TRACK
                  LDA #-8
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_NB_HEAD_NULL
                  LDA #-9
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
 FAT32_ERROR_BOOT_SIGNATURE
                  LDA #-10
 RETURN_IFAT32_READ_BOOT_SECTOR
                  RTL

;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------

IFAT32_COMPUT_DATA_POS
                  setaxl
                  LDA FAT32_Root_Base_Sector+2 ; load the MSB first to not mosify the value of the
                  STA ADDER_A+2; result if a carry occure wnen loading the result in A or B
                  LDA FAT32_Root_Base_Sector
                  STA ADDER_A

                  LDA FAT32_Root_Sector_offset
                  STA ADDER_B
                  LDA FAT32_Root_Sector_offset+2
                  STA ADDER_B+2
                  ;---------------------------------------
                  LDA ADDER_R
                  STA FAT32_Data_Base_Sector
                  LDA ADDER_R+2
                  STA FAT32_Data_Base_Sector+2
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_COMPUT_ROOT_DIR_POS
                  setaxl
                  ;--------- Compute the size of the 2 FAT -------------
                  ; first operand
                  LDA FAT32_Nb_Of_FAT ; 16 bits number
                  STA M0_OPERAND_A
                  ; Second operand
                  LDA FAT32_Sector_per_Fat ; 16 bits number
                  STA M0_OPERAND_B
                  ;------------ add it to the fat ofset -----------
                  ; we have the total number of sector used by the FAT
                  LDA M0_RESULT
                  STA ADDER_A
                  LDA M0_RESULT+2
                  STA ADDER_A+2
                  ; second operand
                  LDA FAT32_FAT_Base_Sector ;  reserved sector + partition ofset (FAT_Partition_address)
                  STA ADDER_B
                  LDA FAT32_FAT_Base_Sector+2
                  STA ADDER_B+2
                  ;---------------------------------------
                  ; we have the physical ofset (in cluster) of the firsr data block
                  LDA ADDER_R
                  STA FAT32_Root_Base_Sector
                  LDA ADDER_R+2
                  STA FAT32_Root_Base_Sector+2
                  RTL

;-------------------------------------------------------------------------------
;
; Get the number of reserved sector and ad it to Partition address(32 bits) to
; comput the address of the first fat loation
;
;-------------------------------------------------------------------------------
IFAT32_COMPUT_FAT_POS
                  setaxl
                  ;---------------------------------------
                  ; first operand
                  LDA FAT32_Nb_Of_reserved_Cluster ; 16 bite number
                  STA ADDER_A
                  LDA #0
                  STA ADDER_A+2
                  ; second operand
                  LDA FAT_Partition_address ; 32 byte number
                  STA ADDER_B
                  LDA FAT_Partition_address+2
                  STA ADDER_B+2
                  ;---------------------------------------
                  ; Get the result , don't really care about the overflow bit as
                  ; it will NEVER (so somone will have the issue one day) happen
                  LDA ADDER_R
                  STA FAT32_FAT_Base_Sector
                  LDA ADDER_R+2
                  STA FAT32_FAT_Base_Sector+2
                  RTL

;-------------------------------------------------------------------------------
;
;
;
;
;-------------------------------------------------------------------------------
IFAT32_DEC_FAT_Linked_Entry
                  PHA
                  LDA FAT32_FAT_Linked_Entry
                  STA ADDER_A
                  LDA FAT32_FAT_Linked_Entry+2
                  STA ADDER_A+2
                  LDA #$FFFF ; load -1 in comp 2
                  STA ADDER_B
                  LDA #$FFFF
                  STA ADDER_B+2
                  LDA ADDER_R
                  STA FAT32_FAT_Linked_Entry
                  LDA ADDER_R+2
                  STA FAT32_FAT_Linked_Entry+2
                  PLA
                  RTL

;-------------------------------------------------------------------------------
;
; FAT32_Curent_Directory_entry_value contain the long name file to get the data from
;
;
;-------------------------------------------------------------------------------
IFAT32_GET_LONG_NAME_STRING
                  setaxl
                  PHX
                  PHA
                  LDA FAT32_LONG_FILE_NAME_BUFFER_pointer
                  TAX
                  LDA FAT32_Curent_Directory_entry_value+1
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+3
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+5
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+7
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+9
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+14
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+16
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+18
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+20
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+22
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+24
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+28
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  LDA FAT32_Curent_Directory_entry_value+30
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
                  INX
                  TXA
                  STA FAT32_LONG_FILE_NAME_BUFFER_pointer
                  PLA
                  PLX
                  RTL

;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the (root/normal) directory entry to get the long
; name for
;
;-------------------------------------------------------------------------------
FAT32_Temp_16_bite              .word 0
FAT32_Curent_Directory_entry_value_back_up     .fill 32,0 ; store the 32 byte of root entry
IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry .word 0

IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME
                  setaxl
                  PHX
                  PHA ; Save the root entry index we want get the long for
                  ; reset the buffer pointer to write the new LFN
                  LDA #0
                  ;STA @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
                  STA FAT32_LONG_FILE_NAME_BUFFER_pointer
                  PLA
                  PHA

                  ; save the curent folder entry value
                  PHA
                  PHX
                  PHY
                  LDA FAT32_Temp_16_bite
                  INC A
                  STA FAT32_Temp_16_bite
                  setas
                  setdbr `FAT32_Curent_Directory_entry_value
                  setal
                  LDA #<>FAT32_Curent_Directory_entry_value
                  TAX
                  LDA #<>FAT32_Curent_Directory_entry_value_back_up
                  TAY
                  LDA #31
                  MVN `FAT32_Curent_Directory_entry_value, `FAT32_Curent_Directory_entry_value_back_up
                  PlY
                  PLX
                  PLA

                  CMP #0
                  BNE IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__READ_THE_PREVIOUS_ENTRY ; scan the previous folder entry to get the long name string
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__NO_MORE_ENTRY_TO_READ:
                  LDA #-1
                  BRL IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__EXIT
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__READ_THE_PREVIOUS_ENTRY:
                  DEC A; read the previous entry
                  CMP #$FFFF
                  BEQ IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__NO_MORE_ENTRY_TO_READ
                  ;--------------------- Back up the curent folder entry --------------------------
 .comment
 PHA
 PHX
 PHY
 LDA @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
 CMP #0
 BEQ IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__BACKUP_ALREADDY_DONE
 setas
 setdbr `FAT32_Curent_Directory_entry_value
 setal
 LDA #<>FAT32_Curent_Directory_entry_value
 TAX
 LDA #<>FAT32_Curent_Directory_entry_value_back_up
 TAY
 LDA #31
 MVN `FAT32_Curent_Directory_entry_value, `FAT32_Curent_Directory_entry_value_back_up
 LDA #1 ; active the flag to restore the folder entry prior to the function call
 STA  @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__BACKUP_ALREADDY_DONE:
 PlY
 PLX
 PLA
 .endc
                  ;--------------------------------------------------------------------------------
                  PHA ; save thwe curent folder entry
                  JSL IFAT32_GET_DIRECTORY_ENTRY
                  ;;JSL FAT32_PRINT_Root_entry_value
                  LDA FAT32_Curent_Directory_entry_value +11 ; test the dirrectory entry type
                  AND #$00FF
                  CMP #$0F ; test if it's a long name entry
                  BNE IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__ERROR_IN_LONG_NAME_ORDER ; all the long name sould be aone after the otherone
                  BRA IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__TEST_FOR_FIRST_LONG_NAME_ENTRY
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__ERROR_IN_LONG_NAME_ORDER:
                  PLA ; get the foler index back
                  LDA #-2
                  BRL IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__EXIT
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__TEST_FOR_FIRST_LONG_NAME_ENTRY:
                  JSL IFAT32_GET_LONG_NAME_STRING
                  LDA FAT32_Curent_Directory_entry_value
                  AND #$0040
                  CMP #$40
                  BNE IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__READ_THE_PREVIOUS_ENTRY_1
                  BRA IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__END_READDING_LOOP
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__READ_THE_PREVIOUS_ENTRY_1:
                  PLA ; get the foler index back
                  BRL IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__READ_THE_PREVIOUS_ENTRY
                  ;--------------------- end the long name -----------------------
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__END_READDING_LOOP:
                  LDA FAT32_LONG_FILE_NAME_BUFFER_pointer
                  TAX
                  PLA ; get the foler index back
                  LDA #0 ; end of string
                  STA FAT32_LONG_FILE_NAME_BUFFER_256,x
 .comment
 PHA
 PHX
 PHY
 LDA #$0D
 JSL IPUTC
 LDX #<>FAT32_LONG_FILE_NAME_BUFFER_256
 LDA #`FAT32_LONG_FILE_NAME_BUFFER_256
 JSL IPUTS_ABS
 LDA #$0D
 JSL IPUTC
 PLY
 PLX
 PLA
 .endc
                  LDA #1
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__EXIT:
                  ;--------------------- Restore the curent folder entry--------------------------
 .comment
 PHA
 PHX
 PHY
 LDA  @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
 CMP #0
 BEQ IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__EXIT_NO_RESTOR
 LDA #<>FAT32_Curent_Directory_entry_value_back_up
 TAX
 LDA #<>FAT32_Curent_Directory_entry_value
 TAY
 LDA #31
 MVN `FAT32_Curent_Directory_entry_value_back_up, `FAT32_Curent_Directory_entry_value
 LDA #0 ; active the flag to restore the folder entry prior to the function call
 STA  @l IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME_Need_to_restor_folder_entry
 IFAT32_GET_DIRECTORY_ENTRY_LONG_NAME__EXIT_NO_RESTOR:
 PLY
 PLX
 PLA
 .endc
                  PHA
                  PHX
                  PHY
                  setas
                  setdbr `FAT32_Curent_Directory_entry_value
                  setal
                  LDA #<>FAT32_Curent_Directory_entry_value_back_up
                  TAX
                  LDA #<>FAT32_Curent_Directory_entry_value
                  TAY
                  LDA #31
                  MVN `FAT32_Curent_Directory_entry_value_back_up, `FAT32_Curent_Directory_entry_value
                  PlY
                  PLX
                  PLA
                  ;--------------------------------------------------------------------------------
                  PLX ; get the PLA out of the way without modifiying the return value
                  PLX
                  RTL

;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the (root/normal) directory entry to read
;
; 2 Entry possible for this function
; IFAT32_GET_ROOT_DIRECTORY_ENTRY
; IFAT32_GET_DIRECTORY_ENTRY
;
; return value :
;
; -1  =>  end of the file, no more sector
; -2  =>  bad sector
; -3  =>  reserved sector
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_DIRECTORY_ENTRY
                  setaxl
                  PHA
                  ; Set the curent folder cluster index to the ROOT FOLDER sector
                  ; ofset to point to the root directory ofset in the fat
                  ; I need to find the exact way to get this ofset
                  LDA FAT32_Root_Sector_offset
                  STA FAT32_Curent_Folder_start_cluster
                  LDA FAT32_Root_Sector_offset+2
                  STA FAT32_Curent_Folder_start_cluster+2
                  PLA
                  ;-------------------------------------------------------------
IFAT32_GET_DIRECTORY_ENTRY
                  ;-------------------------------------------------------------
                  setaxl
                  PHX
                  PHA ; Save the root entry index we want to read
                  LDX #0 ; compute in witch sector the desired root entry is, 16 entry per sector so we just need to divid the sector size by 16
 IFAT32_GET_DIRECTORY_ENTRY__16_DIV:
                  LSR
                  INC X
                  CPX #4 ; divide by 16
                  BNE IFAT32_GET_DIRECTORY_ENTRY__16_DIV
                  CMP #0
                  BEQ IFAT32_GET_ROOT_DIRECTORY_ENTRY__LOAD_CURENT_BASE_SECTOR ; the entry is in the first folder cluster
                  ;-------------- serarch for the entry location ---------------
                  ; the entry is bigger than 16, so we need to search for the entry cluster linked to the folder
                  STA FAT32_FAT_Linked_Entry ; store the number of sector from the base sector we need to read
                  LDA #0 ; entry index is 16 bit only so that limit at max 65535 entry per folder
                  STA FAT32_FAT_Linked_Entry+2
                  LDA FAT32_Curent_Folder_start_cluster ;FAT32_Root_Base_Sector
                  STA FAT32_FAT_Entry
                  LDA FAT32_Curent_Folder_start_cluster+2; FAT32_Root_Base_Sector +2
                  STA FAT32_FAT_Entry + 2
                  JSL IFAT32_READ_LINKED_FAT_ENTRY
                  ;-------------------- Test for fat validity ------------------
                  ;;;LDA FAT32_FAT_Next_Entry
                  ;;;CMP #0
                  CMP #1 ; sector read is valid
                  BEQ IFAT32_GET_ROOT_DIRECTORY_ENTRY__LOAD_SECTOR
                  BRL IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED_1
                  ;;;BMI IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED_temp_1
                  ;;;BRA IFAT32_GET_ROOT_DIRECTORY_ENTRY__LOAD_SECTOR ; the entry is not null so keep going
 ;;;IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED_temp_1:
                  ;;;LDA FAT32_FAT_Next_Entry+2
                  ;;;CMP #0
                  ;;;BMI IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED
                  ;;;BRA IFAT32_GET_ROOT_DIRECTORY_ENTRY__LOAD_SECTOR ; the entry is not null so keep going
 ;;;IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED: BRL IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED_1
                  ;-------------------------------------------------------------
 IFAT32_GET_ROOT_DIRECTORY_ENTRY__LOAD_CURENT_BASE_SECTOR: ; set the cluster we want to read from the disc
                  LDA FAT32_Curent_Folder_start_cluster
                  STA FAT32_FAT_Next_Entry
                  LDA FAT32_Curent_Folder_start_cluster+2
                  STA FAT32_FAT_Next_Entry+2
 IFAT32_GET_ROOT_DIRECTORY_ENTRY__LOAD_SECTOR:
                  ;-------------------------------------------------------------
                  ;------- From here we have the sector to read from the FAT point of vue -----
                  ;-------------------------------------------------------------
                  ;------ comput the real sector ofset ---------
                  ; first operand
                  LDA FAT32_FAT_Next_Entry ;
                  STA ADDER_A
                  LDA FAT32_FAT_Next_Entry+2
                  STA ADDER_A+2
                  ; second operand Fat data location
                  LDA FAT32_Root_Base_Sector ; 32 byte number
                  STA ADDER_B
                  LDA FAT32_Root_Base_Sector+2
                  STA ADDER_B+2
                  ;------ remove 2 sector as the all fat is ofseted  ---------
                  ; first operand
                  LDA ADDER_R+2 ;
                  STA ADDER_A+2
                  LDA ADDER_R
                  STA ADDER_A
                  ; second operand remover 2 (comp2 2 => FFFFFFFE)
                  LDA #$FFFE
                  STA ADDER_B
                  LDA #$FFFF
                  STA ADDER_B+2
                  ;---------------------------------------
                  ; test if the sector is alreaddy loaddes in RAM
                  LDA ADDER_R
                  CMP FAT32_Curent_Directory_Sector_loaded_in_ram
                  BNE IFAT32_GET_ROOT_DIRECTORY_ENTRY__NEED_TO_LOAD_A_NEW_SECTOR
                  LDA ADDER_R+2
                  CMP FAT32_Curent_Directory_Sector_loaded_in_ram+2
                  BNE IFAT32_GET_ROOT_DIRECTORY_ENTRY__NEED_TO_LOAD_A_NEW_SECTOR
                  BEQ FAT32_FDD_SECTOR_ALREADDY_LOADDED_IN_RAM
 IFAT32_GET_ROOT_DIRECTORY_ENTRY__NEED_TO_LOAD_A_NEW_SECTOR:
                  LDA ADDER_R+2
                  STA FAT32_Curent_Directory_Sector_loaded_in_ram+2 ; save the new sector to load
                  LDA ADDER_R
                  STA FAT32_Curent_Directory_Sector_loaded_in_ram
                  LDA #`FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Curent_Directory_Sector_loaded_in_ram+2 ; Get the ROOT directory sector to read
                  TAX
                  LDA FAT32_Curent_Directory_Sector_loaded_in_ram
                  JSL IFAT_READ_SECTOR
                  PLA
                  PLA
 FAT32_FDD_SECTOR_ALREADDY_LOADDED_IN_RAM:
                  ; get the root entry now we have the right sector loaded in RAM
                  PLA ; GET the root entry
                  ;PHA
                  AND #$0F ; get only the 4 first byte to get the 16 value ofset in the root entry sector loades in ram (16 entry per sector)
                  ASL
                  ASL
                  ASL
                  ASL
                  ASL ; now A contain the ofset to read the root entry from
                  CLC
                  ADC #<>FAT32_FOLDER_ADDRESS_BUFFER_512
                  TAX
                  LDA #<>FAT32_Curent_Directory_entry_value
                  TAY
                  LDA #31
                  MVN `FAT32_FOLDER_ADDRESS_BUFFER_512, `FAT32_Curent_Directory_entry_value
                  LDA #1
                  BRA IFAT32_GET_ROOT_DIRECTORY_ENTRY___EXIT_OK
 IFAT32_GET_ROOT_DIRECTORY_ENTRY__ERROR_RETURNED_1:
                  PLX
 IFAT32_GET_ROOT_DIRECTORY_ENTRY___EXIT_OK
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
; Get the content of the FAT entry index pointed by FAT32_FAT_Entry
; in FAT32_FAT_Next_Entry
;
; JSL IFAT32_GET_ROOT_DIRECTORY_ENTRY
; LDA #5
; STA FAT32_FAT_Entry
; LDA #0
; STA FAT32_FAT_Entry+2
;
;-------------------------------------------------------------------------------
FAT32_IFAT_GET_FAT_ENTRY
                  PHA
                  PHX
                  PHY
 ;BRA TEST_TEXT_1397
 ;text_1397 .text "------ GET FAT ENTRY ------",0
 ;TEST_TEXT_1397:
 ;LDX #<>text_1397
 ;LDA #`text_1397
 ;JSL IPUTS_ABS
 ;LDA #$0D
 ;JSL IPUTC
                  ; find in witch sector the fat entry is suposed to be
                  ;------- Test id the FAT entry is in the first cluster -------
                  LDA FAT32_FAT_Entry+2
                  CMP #0
                  BNE FAT32_FAT_ENTRY_FIND_THE_CLUSTER_32_BYTE_NUMBER ; the FAT entry is definitly not in the first FAT cluster as MSB != 0
                  STA FAT32_FAT_Next_Entry+2 ; the MSB of the sector will be for sure 0
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; /128 (512/4)=> 128 entry per sector
                  STA FAT32_FAT_Next_Entry
                  CMP #0
                  BNE FAT32_FAT_ENTRY_FIND_THE_CLUSTER_16_BYTE_NUMBER
                  BRA FAT32_ENTRY_SECTOR_LOCATION_FIND ;  FAT entry is in  first FAT clustrer (entry smaller than 128)
 FAT32_FAT_ENTRY_FIND_THE_CLUSTER_32_BYTE_NUMBER
                  ; ----- shift the 32 Byte FAT entry by 7 (divide by 128) ------
                  ;-------- to comput the FAT cluster to load in memory --------
                  LDA FAT32_FAT_Entry+2
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; /128 (512/4)=> 128 entry per sector
                  STA FAT32_FAT_Next_Entry+2 ; use FAT32_FAT_Next_Entry as a temporary variable
                  LDA FAT32_FAT_Entry+2 ;extract the 7 bits of the HIGHT part of FAT32_FAT_Entry to casrry them in the LOW part
                  AND #$007F
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A ; get the 4 bit in the right position to be added to the LOW part
                  STA FAT32_FAT_Next_Entry
 FAT32_FAT_ENTRY_FIND_THE_CLUSTER_16_BYTE_NUMBER
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; divide the high part of the FAT entry requested by 16  because there is 16 FAt entry per sector
                  AND #$7FFF
                  ORA FAT32_FAT_Next_Entry
                  STA FAT32_FAT_Next_Entry ; Now contain the 32 bit FAT Cluster to load
 FAT32_ENTRY_SECTOR_LOCATION_FIND:
                  ;------ comput the real sector ofset ---------
                  ; first operand
                  LDA FAT32_FAT_Next_Entry ;
                  STA ADDER_A
                  LDA FAT32_FAT_Next_Entry+2
                  STA ADDER_A+2
                  ; second operand
                  LDA FAT32_FAT_Base_Sector ; 32 byte number
                  STA ADDER_B
                  LDA FAT32_FAT_Base_Sector+2
                  STA ADDER_B+2
                  ;---------------------------------------
                  ; test if the sector is alreaddy loaddes in RAM
                  LDA ADDER_R
                  CMP FAT32_FAT_Sector_loaded_in_ram
                  BNE FAT32_IFAT_GET_FAT_ENTRY___NEED_TO_LOAD_A_NEW_SECTOR
                  LDA ADDER_R+2
                  CMP FAT32_Curent_Directory_Sector_loaded_in_ram+2
                  BNE FAT32_IFAT_GET_FAT_ENTRY___NEED_TO_LOAD_A_NEW_SECTOR
                  BEQ FAT32_IFAT_GET_FAT_ENTRY___SECTOR_ALREADDY_LOADDED_IN_RAM
 FAT32_IFAT_GET_FAT_ENTRY___NEED_TO_LOAD_A_NEW_SECTOR:
                  LDA ADDER_R+2
                  STA FAT32_FAT_Sector_loaded_in_ram+2 ; save the new sector to load
                  LDA ADDER_R
                  STA FAT32_FAT_Sector_loaded_in_ram
                  LDA #`FAT32_FAT_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FAT_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Sector_loaded_in_ram+2 ; read the ROOT directory sector saved at the begining of the function
                  TAX
                  LDA FAT32_FAT_Sector_loaded_in_ram
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX
                  ; from here the right FAT sector is loades in ram
 FAT32_IFAT_GET_FAT_ENTRY___SECTOR_ALREADDY_LOADDED_IN_RAM:
                  LDA FAT32_FAT_Entry
                  AND #$007F ; get only the 7 first byte to get the ofset in the curent FAT cluster loades
                  ASL
                  ASL ; *4 to point to the FAT entry 32 byte
                  ;STA FAT32_FAT_Next_Entry+2
                  ;LDA #<>FAT32_FAT_ADDRESS_BUFFER_512
                  CLC
                  ;ADC FAT32_FAT_Next_Entry+2                ; Add the ofset FAT entry to the data bufer wgere the FAT data is loaded
                  ADC #<>FAT32_FAT_ADDRESS_BUFFER_512
                  TAX
                  LDA #<>FAT32_FAT_Next_Entry
                  TAY
                  LDA #3 ; read 4 byte
                  MVN `FAT32_FAT_ADDRESS_BUFFER_512,`FAT32_FAT_Next_Entry
                  PLY
                  PLX
                  PLA
                  RTL

;-------------------------------------------------------------------------------
;
; Upate the content of the FAT entry index pointed by FAT32_FAT_Entry
; with the value of FAT32_FAT_ENTRY_VALUE_TO_WRITE
;
;-------------------------------------------------------------------------------
FAT32_Temp_UPDATE_FAT_32_bite               .dword 0
FAT32_FAT_ENTRY_VALUE_TO_WRITE                       .dword 0

FAT32_CLEAR_FAT_ENTRY
                  PHA
                  LDA #0
                  STA FAT32_FAT_ENTRY_VALUE_TO_WRITE
                  STA FAT32_FAT_ENTRY_VALUE_TO_WRITE+2
                  PLA
FAT32_UPDATE_FAT_ENTRY
                  PHA
                  PHX
                  PHY
                  ; find in witch sector the fat entry is suposed to be
                  ;------- Test id the FAT entry is in the first cluster -------
                  LDA FAT32_FAT_Entry+2
                  CMP #0
                  BNE FAT32_UPDATE_FAT_ENTRY__FIND_THE_CLUSTER_32_BYTE_NUMBER ; the FAT entry is definitly not in the first FAT cluster as MSB != 0
                  STA FAT32_Temp_UPDATE_FAT_32_bite+2 ; the MSB of the sector will be for sure 0
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; /128 (512/4)=> 128 entry per sector
                  STA FAT32_Temp_UPDATE_FAT_32_bite
                  CMP #0
                  BNE FAT32_UPDATE_FAT_ENTRY__FIND_THE_CLUSTER_16_BYTE_NUMBER
                  BRA FAT32_UPDATE_FAT_ENTRY__SECTOR_LOCATION_FIND ;  FAT entry is in  first FAT clustrer (entry smaller than 128)
 FAT32_UPDATE_FAT_ENTRY__FIND_THE_CLUSTER_32_BYTE_NUMBER:
                  ; ----- shift the 32 Byte FAT entry by 7 (divide by 128) ------
                  ;-------- to comput the FAT cluster to load in memory --------
                  LDA FAT32_FAT_Entry+2
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; /128 (512/4)=> 128 entry per sector
                  STA FAT32_Temp_UPDATE_FAT_32_bite+2 ;
                  LDA FAT32_FAT_Entry+2 ;extract the 7 bits of the HIGHT part of FAT32_FAT_Entry to casrry them in the LOW part
                  AND #$007F
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A ; get the 4 bit in the right position to be added to the LOW part
                  STA FAT32_Temp_UPDATE_FAT_32_bite
 FAT32_UPDATE_FAT_ENTRY__FIND_THE_CLUSTER_16_BYTE_NUMBER:
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; divide the high part of the FAT entry requested by 16  because there is 16 FAt entry per sector
                  AND #$7FFF
                  ORA FAT32_Temp_UPDATE_FAT_32_bite
                  STA FAT32_Temp_UPDATE_FAT_32_bite ; Now contain the 32 bit FAT Cluster to load
 FAT32_UPDATE_FAT_ENTRY__SECTOR_LOCATION_FIND:
                  ;------ comput the real sector ofset ---------
                  ; first operand
                  LDA FAT32_Temp_UPDATE_FAT_32_bite ;
                  STA ADDER_A
                  LDA FAT32_Temp_UPDATE_FAT_32_bite+2
                  STA ADDER_A+2
                  ; second operand
                  LDA FAT32_FAT_Base_Sector ; 32 byte number
                  STA ADDER_B
                  LDA FAT32_FAT_Base_Sector+2
                  STA ADDER_B+2
                  ;---------------------------------------
                  ; test if the sector is alreaddy loaddes in RAM
                  LDA ADDER_R
                  CMP FAT32_FAT_Sector_loaded_in_ram
                  BNE FAT32_UPDATE_FAT_ENTRY___NEED_TO_LOAD_A_NEW_SECTOR
                  LDA ADDER_R+2
                  CMP FAT32_Curent_Directory_Sector_loaded_in_ram+2
                  BNE FAT32_UPDATE_FAT_ENTRY___NEED_TO_LOAD_A_NEW_SECTOR
                  BEQ FAT32_UPDATE_FAT_ENTRY___SECTOR_ALREADDY_LOADDED_IN_RAM
 FAT32_UPDATE_FAT_ENTRY___NEED_TO_LOAD_A_NEW_SECTOR:
                  LDA ADDER_R+2
                  STA FAT32_FAT_Sector_loaded_in_ram+2 ; save the new sector to load
                  LDA ADDER_R
                  STA FAT32_FAT_Sector_loaded_in_ram
                  LDA #`FAT32_FAT_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FAT_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Sector_loaded_in_ram+2 ; read the ROOT directory sector saved at the begining of the function
                  TAX
                  LDA FAT32_FAT_Sector_loaded_in_ram
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX
                  ; from here the right FAT sector is loades in ram
 FAT32_UPDATE_FAT_ENTRY___SECTOR_ALREADDY_LOADDED_IN_RAM:
                  LDA FAT32_FAT_Entry
                  AND #$007F ; get only the 7 first byte to get the ofset in the curent FAT cluster loades
                  ASL
                  ASL ; *4 to point to the FAT entry 32 byte
                  CLC
                  ADC #<>FAT32_FAT_ADDRESS_BUFFER_512 ; Add the ofset FAT entry to the data bufer wgere the FAT data is loaded
                  ; Update the FAT sector in ram with the new fat index
                  TAY
                  LDA #<>FAT32_FAT_ENTRY_VALUE_TO_WRITE
                  TAX
                  LDA #3 ; writ 4 Byte in the buffer
                  MVN `FAT32_FAT_ENTRY_VALUE_TO_WRITE,`FAT32_FAT_ADDRESS_BUFFER_512
                  ; Write the FAT sector back
                  LDA #`FAT32_FAT_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FAT_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Sector_loaded_in_ram
                  LDX FAT32_FAT_Sector_loaded_in_ram+2
                  JSL IFAT_WRITE_SECTOR
                  PLY
                  PLX
                  PLA
                  RTL

;-------------------------------------------------------------------------------
;
; IN :
; - FAT32_FAT_Linked_Entry number of entry to "jump to" before getting the right sector location
; - FAT32_FAT_Entry FAT entry where to start the linked readding
;
; return value :
;  1  =>  sector found
; -1  =>  end of the file, no more sector
; -2  =>  bad sector
; -3  =>  reserved sector
;-------------------------------------------------------------------------------
IFAT32_READ_LINKED_FAT_ENTRY
                  PHX
 IFAT32_READ_LINKED_FAT_ENTRY___READ_NEXT_FAT:
                  JSL FAT32_IFAT_GET_FAT_ENTRY
 .comment
  ;JSL FAT32_Print_FAT_STATE
  ;----- debug -----
  PHX
  PHA
  BRA TEST_TEXT_799
  text_799 .text $0d,"curent fat entry          ",0
  TEST_TEXT_799:
  LDX #<>text_799
  LDA #`text_799
  JSL IPUTS_ABS       ; print the first line
  LDA #$AF                  ; Set the default text color to light gray on dark gray
  JSL SET_COLOUR
  LDA FAT32_FAT_Entry+2
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA FAT32_FAT_Entry
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$ED                  ; Set the default text color to light gray on dark gray
  JSL SET_COLOUR
  LDA #$0D
  JSL IPUTC
  PLA
  PLX
  ;------------------
  ;----- debug -----
  PHX
  PHA
  LDX #<>TEXT_FAT32___FAT_Entry
  LDA #`TEXT_FAT32___FAT_Entry
  JSL IPUTS_ABS       ; print the first line
  LDA #$BD
  JSL SET_COLOUR
  LDA FAT32_FAT_Entry+2
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA FAT32_FAT_Entry
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$ED                  ; Set the default text color to light gray on dark gray
  JSL SET_COLOUR

  LDA #$0D
  JSL IPUTC
  PLA
  PLX
  ;------------------
  .endc
                  ;-------------------------------------------------------------
                  ; test the fat entry for reserved or bad sector
                  JSL FAT32_Test_Fat_Entry_Validity_Next
                  CMP #1
                  BEQ IFAT32_READ_LINKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  BRL IFAT32_READ_LINKED_FAT_ENTRY___EXIT
                  ;-------------------------------------------------------------

                  ; the fat entry is containning data, now decrementing the
                  ; linked counter  to see if we need to look at the next fat entry
 IFAT32_READ_LINKED_FAT_ENTRY___NEXT_CLUSTER_VALID:
                  JSL IFAT32_DEC_FAT_Linked_Entry
                  LDA FAT32_FAT_Linked_Entry
                  CMP #0
                  BEQ IFAT32_READ_LINKED_FAT_ENTRY___TEST_HIGH_PART
                  LDA FAT32_FAT_Next_Entry
                  STA FAT32_FAT_Entry
                  LDA FAT32_FAT_Next_Entry+2
                  STA FAT32_FAT_Entry+2
                  BRL IFAT32_READ_LINKED_FAT_ENTRY___READ_NEXT_FAT
 IFAT32_READ_LINKED_FAT_ENTRY___TEST_HIGH_PART:
                  LDA FAT32_FAT_Linked_Entry+2
                  CMP #0
                  BEQ IFAT32_READ_LINKED_FAT_ENTRY___ALL_LINKED_FAT_PARSED
                  LDA FAT32_FAT_Next_Entry
                  STA FAT32_FAT_Entry
                  LDA FAT32_FAT_Next_Entry+2
                  STA FAT32_FAT_Entry+2
                  BRL IFAT32_READ_LINKED_FAT_ENTRY___READ_NEXT_FAT
 IFAT32_READ_LINKED_FAT_ENTRY___ALL_LINKED_FAT_PARSED:
                  LDA #1
 IFAT32_READ_LINKED_FAT_ENTRY___EXIT:
                  PLX
                  RTL

;----------------------------------------------------------------------------------------------------------
;
; sellect the right device to read from depending on FAT32_SD_FDD_HDD_SELL
;
; call procedure
;
; LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
; PHA
; LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
; PHA
; LDA FAT32_Sector_to_read
; LDX FAT32_Sector_to_read+2
; JSL IFAT_READ_SECTOR
;----------------------------------------------------------------------------------------------------------
IFAT_READ_SECTOR
                PHA
                LDA FAT32_SD_FDD_HDD_SELL
                CMP FAT32_HDD
                BEQ IFAT_READ_SECTOR__HDD
                CMP FAT32_HDD
                BEQ IFAT_READ_SECTOR__FDD
 IFAT_READ_SECTOR_SD:; will search on the SD card as default one
                PLA ; get the sector to read back
                JSL ISD_READ
                RTL
 IFAT_READ_SECTOR__HDD:
                PLA ; get the sector to read back
                JSL IHDD_READ
                RTL
 IFAT_READ_SECTOR__FDD:
                PLA ; get the sector to read back
                ;JSL IFDD_READ ; not inplemented as it's not working and use fat 12 instead of 32
                RTL

;----------------------------------------------------------------------------------------------------------
;
; sellect the right device to write to depending on FAT32_SD_FDD_HDD_SELL
;
; call procedure
;
; LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
; PHA
; LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
; PHA
; LDA FAT32_Sector_to_read
; LDX FAT32_Sector_to_read+2
; JSL IFAT_WRITE_SECTOR
;----------------------------------------------------------------------------------------------------------
IFAT_WRITE_SECTOR
                PHA
                LDA FAT32_SD_FDD_HDD_SELL
                CMP FAT32_HDD
                BEQ IFAT_WRITE_SECTOR__HDD
                CMP FAT32_HDD
                BEQ IFAT_WRITE_SECTOR__FDD
 IFAT_WRITE_SECTOR_SD:; will search on the SD card as default one
                PLA ; get the sector to read back
                JSL ISD_WRITE
                RTL
 IFAT_WRITE_SECTOR__HDD:
                PLA ; get the sector to read back
                ;JSL IHDD_WRITE
                RTL
 IFAT_WRITE_SECTOR__FDD:
                PLA ; get the sector to read back
                ;JSL IFDD_WRITE ; not inplemented as it's not working and use fat 12 instead of 32
                RTL


;----------------------------------------------------------------------------------------------------------
;
; Read 512 byte of the address in (A << 512)
; the FAT is working on block of 512 so the 8 low bits are never set
;
; call procedure
;
; LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
; PHA
; LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
; PHA
; LDA FAT32_Sector_to_read
; JSL IHDD_READ
;----------------------------------------------------------------------------------------------------------
IHDD_READ       setaxl
                PHA ; save the sector to read
                LDA 8,S
                TAY
                LDA 6,S
                TAY
                PLA
                PHA ; save the sector read for the return value
                ASL A ; convert the sector number into byte count
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A

                ADC #<>data_hard_drive
                TAX


                setas
                LDA 8,S
                STA HDD_MVN_INSTRUCTION_ADDRESS + 1 ; rewrite the second parameter of the instruction in RAM
                setaxl
                LDA #511
 HDD_MVN_INSTRUCTION_ADDRESS  MVN `data_hard_drive,`FAT32_DATA_ADDRESS_BUFFER_512
                PLA
                RTL

;----------------------------------------------------------------------------------------------------------
;
;----------------------------------------------------------------------------------------------------------
ISD_INIT        setaxl
                LDA #SDC_TRANS_INIT_SD
                STA SDC_TRANS_TYPE_REG;
                LDA #SDC_TRANS_START
                STA SDC_TRANS_CONTROL_REG;

 ISD_INIT_TEST_SD_INIT_FLAG:
                LDA SDC_TRANS_STATUS_REG  ; read the bussy state flag : 1 busy / 0 finished
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ ISD_INIT_TEST_SD_INIT_FLAG

                LDA SDC_TRANS_ERROR_REG ; read the error status
                RTL

;----------------------------------------------------------------------------------------------------------
;
;----------------------------------------------------------------------------------------------------------
ISD_READ        ;PHP
                setaxl
                ASL ;get the 512 byte ofset from the sector index
                BCC ISD_READ__NO_OVERFLOW
                PHA
                TXA
                ASL
                CLC
                ADC #1
                TAX
                PLA
                BRA ISD_READ__OVERFLOW_DONE
 ISD_READ__NO_OVERFLOW:
                PHA
                TXA
                ASL
                TAX
                PLA
 ISD_READ__OVERFLOW_DONE:
  .comment
  PHA
  PHX
  BRA _TEST_TEXT_2212
  _text_2212 .text "---- cluser address to read X:A    ",0
  _TEST_TEXT_2212:
  LDX #<>_text_2212
  LDA #`_text_2212
  JSL IPUTS_ABS
  PLA ; get Content of X MSB
  PHA
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  PLA
  PLX
  PHX
  PHA
  TXA
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$0D
  JSL IPUTC
  PLX
  PLA
  .endc
                setas
                STA SDC_SD_ADDR_15_8_REG
                XBA ; get the other part of the 16 byte A register
                STA SDC_SD_ADDR_23_16_REG
                TXA
                AND #$0F
                STA SDC_SD_ADDR_31_24_REG
                LDA #0
                STA SDC_SD_ADDR_7_0_REG ; all the time 0 as we are readding 512 byte block

                LDA #1
                STA SDC_RX_FIFO_CTRL_REG ; Clear the RX FIFO

                LDA #SDC_TRANS_READ_BLK
                STA SDC_TRANS_TYPE_REG;
                LDA #SDC_TRANS_START
                STA SDC_TRANS_CONTROL_REG;

 ISD_READ_TEST_SD_INIT_FLAG:
                LDA SDC_TRANS_STATUS_REG  ; read the bussy state flag : 1 busy / 0 finished
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ ISD_READ_TEST_SD_INIT_FLAG

                LDA SDC_TRANS_ERROR_REG ; read the error status

                ;PHA
                ;LDA #' '
                ;JSL IPUTC
                ;LDA #'E'
                ;JSL IPUTC
                ;PLA
                ;PHA
                ;JSL IPRINT_HEX
                ;LDA #' '
                ;JSL IPUTC
                ;LDA #'B'
                ;JSL IPUTC
                ;LDA #' '
                ;JSL IPUTC
                ;PLA

                CMP #0
                BNE ISD_READ__INIT_RETURN
 ISD_READ_GET_BYTE_COUNT:
                ;LDA SDC_RX_FIFO_DATA_CNT_HI ; get the number of byte in the fifo
                ;JSL IPRINT_HEX
                ;LDA SDC_RX_FIFO_DATA_CNT_LO ; get the number of byte in the fifo
                ;JSL IPRINT_HEX
                ;LDA #$0D
                ;JSL IPUTC

                setas
                LDA 9,S
                STA @l ISD_READ_+ 3
                ;JSL IPRINT_HEX ; print the sector
                LDA 8,S
                STA @l ISD_READ_+ 2
                ;JSL IPRINT_HEX ; print the sector
                LDA 7,S
                STA @l ISD_READ_+ 1
                ;JSL IPRINT_HEX ; print the sector
                ;LDA #$0D
                ;JSL IPUTC

                LDX #0
 ISD_READ__READ_LOOP_BYTE:
                LDA SDC_RX_FIFO_DATA_REG
 ISD_READ_       STA @l FAT32_DATA_ADDRESS_BUFFER_512,x
                ;JSL IPRINT_HEX
                ;JSL IPUTC
                INX
                CPX #$200
                BNE ISD_READ__READ_LOOP_BYTE
                setal
 ISD_READ__INIT_RETURN:
                LDA #1
                STA SDC_RX_FIFO_CTRL_REG ; discard all possible other byt

                ;LDA #$0D
                ;JSL IPUTC
                ;LDA #'-'
                ;JSL IPUTC
                setaxl
                RTL

;----------------------------------------------------------------------------------------------------------
;
;----------------------------------------------------------------------------------------------------------
ISD_WRITE       ;PHP
                setaxl
                ASL ;get the 512 byte ofset from the sector index
                BCC ISD_WRITE__NO_OVERFLOW
                PHA
                TXA
                ASL
                CLC
                ADC #1
                TAX
                PLA
                BRA ISD_WRITE__OVERFLOW_DONE
 ISD_WRITE__NO_OVERFLOW:
                PHA
                TXA
                ASL
                TAX
                PLA
 ISD_WRITE__OVERFLOW_DONE:
                PHA
                PHX
  .comment
  PHA
  PHX
  BRA _TEST_TEXT_1920
  _text_1920 .text "---- cluser address to write X:A    ",0
  _TEST_TEXT_1920:
  LDX #<>_text_1920
  LDA #`_text_1920
  JSL IPUTS_ABS
  PLA ; get Content of X MSB
  PHA
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  PLA
  PLX
  PHX
  PHA
  TXA
  XBA
  JSL IPRINT_HEX
  XBA
  JSL IPRINT_HEX
  LDA #$0D
  JSL IPUTC
  PLX
  PLA
  .endc
                ;---------------------------------------------------------------
                ;------------------  Clear the TX buffer  ----------------------
                ;---------------------------------------------------------------
                setas
                LDA #1
                STA SDC_TX_FIFO_CTRL_REG
                ;---------------------------------------------------------------
                ;--------------  write the byte in the buffer  -----------------
                ;---------------------------------------------------------------
                LDA 13,S
                STA @l ISD_WRITE_+ 3
                ;JSL IPRINT_HEX ; print the sector
                LDA 12,S
                STA @l ISD_WRITE_+ 2
                ;JSL IPRINT_HEX ; print the sector
                LDA 11,S
                STA @l ISD_WRITE_+ 1
                ;JSL IPRINT_HEX ; print the sector
                ;PHA
                ;LDA #$0D
                ;JSL IPUTC
                ;PLA
                LDX #0
 ISD_WRITE__WRITE_LOOP_BYTE:
 ISD_WRITE_     LDA @l FAT32_DATA_ADDRESS_BUFFER_512,x
                ;JSL IPRINT_HEX ; print the sector
                STA SDC_TX_FIFO_DATA_REG
                INX
                CPX #$200
                BNE ISD_WRITE__WRITE_LOOP_BYTE

                ;---------------------------------------------------------------
                ;---------------------  write the address  ---------------------
                ;---------------------------------------------------------------
                setal
                PLX
                PLA
                ;ibfloop bra  ibfloop
                setas
                STA @l SDC_SD_ADDR_15_8_REG
                XBA ; get the other part of the 16 byte A register
                STA @l SDC_SD_ADDR_23_16_REG
                TXA
                AND #$0F
                STA @l SDC_SD_ADDR_31_24_REG
                LDA #0
                STA @l SDC_SD_ADDR_7_0_REG ; all the time 0 as we are readding 512 byte block

                ;---------------------------------------------------------------
                ;----------------  Set the controller in TX mode  --------------
                ;---------------------------------------------------------------
                LDA #SDC_TRANS_WRITE_BLK
                STA SDC_TRANS_TYPE_REG;
                LDA #SDC_TRANS_START
                STA SDC_TRANS_CONTROL_REG;
                ;---------------------------------------------------------------
                ;-------  Wait for the controller to write all the Byte  -------
                ;---------------------------------------------------------------
 ISD_WRITE_TEST_SD_INIT_FLAG:
                LDA SDC_TRANS_STATUS_REG  ; read the bussy state flag : 1 busy / 0 finished
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ ISD_WRITE_TEST_SD_INIT_FLAG

                LDA SDC_TRANS_ERROR_REG ; read the error status
                AND #30 ; get the TX error bits
                ;---------------------------------------------------------------
                ;----------------------  Test for error  -----------------------
                ;---------------------------------------------------------------
                CMP #0
                BNE ISD_WRITE__ERROR_RETURN
                LDA #1
                BRA ISD_WRITE__OK_RETURN
 ISD_WRITE__ERROR_RETURN:
                LDA #-1
 ISD_WRITE__OK_RETURN:
                ;---------------------------------------------------------------
                ;------------------  Clear the TX buffer  ----------------------
                ;---------------------------------------------------------------
                PHA
                LDA #1
                STA SDC_TX_FIFO_CTRL_REG
                PLA
                setaxl
                RTL

;----------------------------------------------------------------------------------------------------------
; will add all the function to display and debug
;----------------------------------------------------------------------------------------------------------

.include "FAT32_Utils.asm"        ; finction to do repetitive and simple tuff
.include "FAT32_Utils_Print.asm"  ; function for display and debugging
.include "FAT_32_Test_Code.asm"   ; code not usefull for the fat or old function

;----------------------------------------------------------------------------------------------------------
; EOF
;----------------------------------------------------------------------------------------------------------

* = $120000
.include "HDD_row_TEXT_HEX.asm" ; fake HDD data

Starwars_text   .text "Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....Episode IV A NEW HOPE It is a period of civil war. Rebel spaceships, striking from a hidden base, have won their first victory against the evil Galactic Empire.  During the battle, Rebel spies managed to steal secret plans to the Empire's ultimate weapon, the DEATH STAR, an armored space station with enough power to destroy an entire planet.  Pursued by the Empire's sinister agents, Princess Leia races home aboard her starship, custodian of the stolen plans that can save her people and restore freedom to the galaxy.....  	 Episode V THE EMPIRE STRIKES BACK  It is a dark time for the Rebellion. Although the Death Star has been destroyed, Imperial troops have driven the Rebel forces from their hidden base and pursued them across the galaxy.  Evading the dreaded Imperial Starfleet, a group of freedom fighters led by Luke Skywalker has established a new secret base on the remote ice world of Hoth.  The evil lord Darth Vader, obsessed with finding young Skywalker, has dispatched thousands of remote probes into the far reaches of space....  	 Episode VI RETURN OF THE JEDI  Luke Skywalker has returned to his home planet of Tatooine in an attempt to rescue his friend Han Solo from the clutches of the vile gangster Jabba the Hutt.  Little does Luke know that the GALACTIC EMPIRE has secretly begun construction on a new armored space station even more powerful than the first dreaded Death Star.  When completed, this ultimate weapon will spell certain doom for the small band of rebels struggling to restore freedom to the galaxy....  Episode VII THE FORCE AWAKENS  Luke Skywalker has vanished. In his absence, the sinister FIRST ORDER has risen from the ashes of the Empire and will not rest until Skywalker, the last Jedi, has been destroyed.  With the support of the REPUBLIC, General Leia Organa leads a brave RESISTANCE. She is desperate to find her brother Luke and gain his help in restoring peace and justice to the galaxy.  Leia has sent her most daring pilot on a secret mission to Jakku, where an old ally has discovered a clue to Luke's whereabouts....  	 Episode VIII THE LAST JEDI  The FIRST ORDER reigns. Having decimated the peaceful Republic, Supreme Leader Snoke now deploys the merciless legions to seize military control of the galaxy.  Only General Leia Organa's band of RESISTANCE fighters stand against the rising tyranny, certain that Jedi Master Luke Skywalker will return and restore a spark of hope to the fight.  But the Resistance has been exposed. As the First Order speeds toward the rebel base, the brave heroes mount a desperate escape....  	 Episode IX THE RISE OF SKYWALKER  The dead speak! The galaxy has heard a mysterious broadcast, a threat of REVENGE in the sinister voice of the late EMPEROR PALPATINE.  GENERAL LEIA ORGANA dispatches secret agents to gather intelligence, while REY, the last hope of the Jedi, trains for battle against the diabolical FIRST ORDER.  Meanwhile, Supreme Leader KYLO REN rages in search of the phantom Emperor, determined to destroy any threat to his power....",0
