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
FAT32_Curent_Folder_Sector_loaded_in_ram .dword 0  ; store the actual Folder sector loades in ram
FAT32_Curent_Folder_entry_value  .fill 32,0 ; store the 32 byte of root entry

FAT32_FAT_Base_Sector           .dword 0
FAT32_FAT_Sector_loaded_in_ram  .dword 0  ; store the actual FAT sector loades in ram
FAT32_FAT_Entry                 .dword 0
FAT32_FAT_Next_Entry            .dword 0  ; store the next 32 bit FAT entry associated to the FAT entry in 'FAT32_FAT_Entry'
FAT32_FAT_Linked_Entry          .dword 0

FAT32_Data_Base_Sector          .dword 0  ; contain the sector index of the first data in the FAT volume (that include the reserved cluster after the fat) => used to convert from cluster count to fat index
MBR_Partition_address           .dword 0 ; ofset of the curent FAT volume used

FAT32_Curent_Folder_start_cluster   .dword 0 ; Hold the first cluster from the FAT perspective => real cluster  = FAT32_Curent_Folder_start_cluster + FAT32_Data_Base_Sector
FAT32_Curent_Folder_curent_cluster .dword 0
FAT32_Curent_File_base_cluster   .dword 0 ; Hold the first cluster from the FAT perspective => real cluster  = FAT32_Curent_File_base_cluster + FAT32_Data_Base_Sector
FAT32_Curent_File_curent_cluster .dword 0

FAT32_Temp_32_bite              .dword 0

FAT32_Sector_to_read            .dword 0
FAT32_SD_FDD_HDD_Sell           .word 0
;file_to_load_f32    .text "SDFGVGH TXT"
file_to_load_f32    .text "TEXT_T~1TXT"
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
              STA FAT32_Curent_Folder_Sector_loaded_in_ram
              STA FAT32_FAT_Sector_loaded_in_ram
              LDA #0
              STA FAT32_Sector_loaded_in_ram+2
              STA FAT32_Curent_Folder_Sector_loaded_in_ram+2
              STA FAT32_FAT_Sector_loaded_in_ram+2

              JSL IFAT32_GET_ROOT_ENTRY

              ;LDA #5
              ;STA FAT32_FAT_Entry
              ;LDA #0
              ;STA FAT32_FAT_Entry+2
              ;JSL FAT32_IFAT_GET_FAT_ENTRY
              RTL
FAT32_test
              LDA 0;
              JSL IFAT32_GET_ROOT_ENTRY
              LDA #5
              STA FAT32_FAT_Entry
              LDA #0
              STA FAT32_FAT_Entry+2
              JSL FAT32_IFAT_GET_FAT_ENTRY
              LDA #$0D
              JSL IPUTC
              ;-------------------------
              JSL FAT32_LS_CMD
              LDA #$0D
              JSL IPUTC
              ;-------------------------
              ;LDA #`file_to_load_f32 ; load the byte nb 3 (bank byte)
              ;PHA
              ;LDA #<>file_to_load_f32 ; load the low world part of the buffer address
              ;PHA
              JSL FAT32_Open_File
              CMP #1
              BNE FAT32_test__Faill_To_Find_file
              JSL FAT32_Read_File
              JSL FAT32_Print_Cluster
FAT32_test__Faill_To_Find_file
              ;-------------------------
              RTL
;-------------------------------------------------------------------------------
FAT32_Print_Cluster
              LDA #$0D
              JSL IPUTC
              LDX #0
FAT32_Print_Cluster_line
              LDY #0
FAT32_Print_Cluster_Byte
              LDA FAT32_DATA_ADDRESS_BUFFER_512,X
              JSL IPRINT_HEX
              LDA #$20
              JSL IPUTC
              INY
              CPY #16
              BNE FAT32_Print_Cluster_Byte
              LDA #$0D
              JSL IPUTC
              INX
              CPX #512
              BNE FAT32_Print_Cluster_line
              RTL
Wait_loop:
              PHX
              LDX #1000
              JSL ILOOP_MS
              PLX
              RTL
;-------------------------------------------------------------------------------
;
; display the file name of the 32 first root entry
;
;-------------------------------------------------------------------------------
FAT32_LS_CMD      LDX #0 ; start by readding the first folder entry
LDA #'s'
JSL IPUTC
LDX #0 ; start by readding the first folder entry
FAT32_LS_CMD__Read_Next_Folder_Entry:
LDA #'l'
JSL IPUTC
JSL Wait_loop
                  TXA
                  CPX #$20
                  BEQ FAT32_LS_CMD__EXIT
LDA #'k'
JSL IPUTC
TXA
                  JSL IFAT32_GET_ROOT_ENTRY
JSL FAT32_PRINT_Root_entry_value
LDA #$0D
JSL IPUTC
TXA
JSL IPRINT_HEX
LDA #$0D
JSL IPUTC
LDA #'h'
JSL IPUTC
BRA FAT32_LS_CMD_keep_1
FAT32_LS_CMD__Read_Next_Folder_Entry_2: bra FAT32_LS_CMD__Read_Next_Folder_Entry
FAT32_LS_CMD_keep_1:
                  INC X
                  LDA FAT32_Curent_Folder_entry_value +11
                  AND #$00FF
                  CMP #$0F ; test if it's a long name entry
                  BEQ FAT32_LS_CMD__Read_Next_Folder_Entry_2
                  AND #$10
                  CMP #$10 ;CMP #$20 ; if different from 0x20 its nor a file name entry (need to confirm that)
                  BEQ FAT32_LS_CMD__print_folder
                  LDA FAT32_Curent_Folder_entry_value
                  AND #$00FF
                  CMP #$E5 ; test if the entry is deleted
                  BEQ FAT32_LS_CMD__Read_Next_Folder_Entry_2
                  ;-------
                  ;debug
                  LDA #'i'
                  JSL IPUTC
                  JSL FAT32_Print_File_Name
                  LDA #$0D
                  JSL IPUTC
                  BRA FAT32_LS_CMD__Read_Next_Folder_Entry_2
FAT32_LS_CMD__print_folder:
                  LDA #'j'
                  JSL IPUTC
                  JSL FAT32_Print_Folder_Name
                  LDA #$0D
                  JSL IPUTC
                  BRA FAT32_LS_CMD__Read_Next_Folder_Entry_2
FAT32_LS_CMD__EXIT:
PHX
PHA
LDX #<>TEXT_____DEBUG_END_LS
LDA #`TEXT_____DEBUG_END_LS
JSL IPRINT_ABS
PLA
PHX
                  RTL

;-------------------------------------------------------------------------------
; Search for the file name in the root directory
;
; FOR NOW THE CURENT DIRECTORY IS THE ROOT DIRECTORY
;
;-------------------------------------------------------------------------------
FAT32_Open_File   LDX #0 ; start by readding the first folder entry
FAT32_Open_File_Read_Next_Folder_Entry
                  TXA
                  CMP #32
                  BEQ FAT32_Open_File__EXIT
                  JSL IFAT32_GET_ROOT_ENTRY
                  INC X
                  LDA FAT32_Curent_Folder_entry_value +11
                  AND #$00FF
                  CMP #$0F ; test if it's a long name entry
                  BEQ FAT32_Open_File_Read_Next_Folder_Entry
                  CMP #$20 ; if different from 0x20 its nor a file name entry (need to confirm that)
                  BEQ FAT32_Open_File_Read_Next_Folder_Entry
                  LDA FAT32_Curent_Folder_entry_value
                  AND #$00FF
                  CMP #$E5 ; test if the entry is deleted
                  BEQ FAT32_Open_File_Read_Next_Folder_Entry
                  ;-------------------------------------------------------------
                  ; copare the file name we want to load and the folder entry file name
                  JSL FAT32_Print_File_Name
                  LDA #$0D
                  JSL IPUTC
                  PHX
                  LDX #-1
                  setas
FAT32_Open_File__CHAR_MATCHING
                  INC X
                  CPX #11 ; FAT12 file or folder size
                  BEQ FAT32_Open_File__STRING_MATCHED
                  LDA FAT32_Curent_Folder_entry_value,X
                  LDA file_to_load_f32,X
                  CMP FAT32_Curent_Folder_entry_value,X
                  BEQ FAT32_Open_File__CHAR_MATCHING
                  PLX
                  setal
                  BRA FAT32_Open_File_Read_Next_Folder_Entry

FAT32_Open_File__STRING_MATCHED
                  PLX
                  setal
                  LDA FAT32_Curent_Folder_entry_value + $1A ; Low two bytes of first cluster
                  STA FAT32_Curent_File_base_cluster
                  LDA #0
                  STA FAT32_Curent_File_curent_cluster
                  LDA FAT32_Curent_Folder_entry_value + $1C ; High two bytes of first cluster
                  STA FAT32_Curent_File_base_cluster + 2
                  LDA #0
                  STA FAT32_Curent_File_curent_cluster + 2
                  LDA #1
FAT32_Open_File__EXIT
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_Read_File
                  LDA FAT32_Curent_File_curent_cluster
                  CMP #0
                  BNE FAT32_Read_File___Get_Next_Sector
                  LDA FAT32_Curent_File_curent_cluster+2
                  CMP #0
                  BNE FAT32_Read_File___Get_Next_Sector
                  ; the first sector index is empty, it mean that the file has never bin read
                  LDA FAT32_Curent_File_base_cluster
                  STA FAT32_Curent_File_curent_cluster
                  STA FAT32_FAT_Entry
                  LDA FAT32_Curent_File_base_cluster+2
                  STA FAT32_Curent_File_curent_cluster+2
                  STA FAT32_FAT_Entry+2
                  BRA FAT32_Read_File___Read_Sector
FAT32_Read_File___Get_Next_Sector
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  JSL FAT32_Test_Fat_Entry_Validity
                  CMP #-1
                  BEQ FAT32_Read_File___End_OF_File
                  CMP #0
                  BNE FAT32_Read_File___Reserved_Or_Bad_Sector
FAT32_Read_File___Read_Sector
                  LDA FAT32_Curent_File_base_cluster
                  CLC
                  ADC FAT32_Data_Base_Sector
                  STA FAT32_Sector_to_read

                  LDA FAT32_Curent_File_base_cluster+2
                  ADC FAT32_Data_Base_Sector + 2
                  STA FAT32_Sector_to_read + 2

                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Sector_to_read
                  JSL IFAT_READ_SECTOR
                  PLA
                  PLA

FAT32_Read_File___End_OF_File
FAT32_Read_File___Reserved_Or_Bad_Sector
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_Print_File_Name
                  PHX
                  PHA
                  LDA FAT32_Curent_Folder_entry_value
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +1
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +2
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +3
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +4
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +5
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +6
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +7
                  JSL IPUTC
                  LDA #'.'
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +8
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +9
                  JSL IPUTC
                  LDA FAT32_Curent_Folder_entry_value +10
                  JSL IPUTC
                  LDA #$0D
                  JSL IPUTC
                  PLA
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
; print the folder name from the curent folder entry
;
;-------------------------------------------------------------------------------
FAT32_Print_Folder_Name
                  PHX
                  LDX #0
FAT32_Print_Folder_Name__Print_char:
                  LDA FAT32_Curent_Folder_entry_value,x
                  JSL IPUTC
                  INX
                  CPX #$B
                  BNE FAT32_Print_Folder_Name__Print_char
                  LDA #$0D
                  JSL IPUTC
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
; display the ROOT entry in hex and in ASCII
;
;-------------------------------------------------------------------------------
FAT32_PRINT_Root_entry_value
                  PHX
                  PHY
                  PHA
                  LDX #0
                  FAT32_PRINT_Root_entry_value_loop_1:
                  LDA @l FAT32_Curent_Folder_entry_value,x
                  JSL IPRINT_HEX
                  INX
                  CPX #32
                  BNE FAT32_PRINT_Root_entry_value_loop_1
                  LDA #$0D
                  JSL IPUTC
                  LDX #0
                  FAT32_PRINT_Root_entry_value_loop_2:
                  LDA @l FAT32_Curent_Folder_entry_value,x
                  JSL IPUTC
                  INX
                  CPX #32
                  BNE FAT32_PRINT_Root_entry_value_loop_2
                  LDA #$0D
                  JSL IPUTC
                  PLA
                  PLY
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
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
                  STA MBR_Partition_address
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X+8+2
                  CMP #0
                  BEQ READ_MBR_Partition_Entry_MSB_Null
                  LDY #1
READ_MBR_Partition_Entry_MSB_Null:
                  STA MBR_Partition_address+2

                  CPY #1 ; curent MBR entry not nul (sector location)
                  BEQ READ_MBR_Partition_valid_address
                  CPX #$1FE
                  BEQ READ_MBR_End_Scan_no_partition
                  TXA ; Conput the next NBR entry position
                  ADC #MBR_Partition_Entry_size
                  TAX
                  BRA READ_MBR_Scan

READ_MBR_Partition_valid_address: ; the number in MBR_Partition_address is an ofset in cluster of a Partiton
                  LDX #<>Partition_ofset_text
                  LDA #`Partition_ofset_text
                  JSL IPUTS_ABS       ; print the first line
                  LDA #'0'
                  JSL IPUTC
                  LDA #'x'
                  JSL IPUTC
                  LDA MBR_Partition_address +3
                  JSL IPRINT_HEX
                  LDA MBR_Partition_address +2
                  JSL IPRINT_HEX
                  LDA MBR_Partition_address +1
                  JSL IPRINT_HEX
                  LDA MBR_Partition_address
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
                  ;LDA MBR_Partition_address+2 ; dont use X value for now IFAT_READ_SECTOR is a dummy function unlit I ger the real HDD hardware driver
                  ;TAX
                  ;LDA MBR_Partition_address
                  ;JSL IFAT_READ_SECTOR

READ_MBR_End_Scan_no_partition:
                  LDA #-1
READ_MBR_End:
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_READ_BOOT_SECTOR
                  setaxl
                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA MBR_Partition_address+2 ; dont use X value for now IFAT_READ_SECTOR is a dummy function unlit I ger the real HDD hardware driver
                  TAX
                  LDA MBR_Partition_address
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
                  LDA FAT32_FAT_Base_Sector ;  reserved sector + partition ofset (MBR_Partition_address)
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
IFAT32_GET_ROOT_FIRST_ENTRY
                  setaxl
                  RTL
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_NEXT_ENTRY
                  setaxl
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
                  LDA MBR_Partition_address ; 32 byte number
                  STA ADDER_B
                  LDA MBR_Partition_address+2
                  STA ADDER_B+2
                  ;---------------------------------------
                  ; Get the result , don't really care about the overflow bit as
                  ; it will NEVER (so somone will have the issue one day) happen
                  LDA ADDER_R
                  STA FAT32_FAT_Base_Sector
                  LDA ADDER_R+2
                  STA FAT32_FAT_Base_Sector+2
                  RTL
;
;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the root directory entry to read
;
;-------------------------------------------------------------------------------

IFAT32_READ_LIKED_FAT_ENTRY
                  PHX
;----- debug -----

PHX
PHA
LDX #<>TEXT_____DEBUG______FAT_L_IN
LDA #`TEXT_____DEBUG______FAT_L_IN
JSL IPUTS_ABS       ; print the first line
LDA #$0D
JSL IPUTC
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
LDA #$0D
JSL IPUTC
PLA
PLX
;-----------------
IFAT32_READ_LIKED_FAT_ENTRY___READ_NEXT_FAT:
                  JSL FAT32_IFAT_GET_FAT_ENTRY
;JSL FAT32_Print_FAT_STATE
                  ;-------------------------------------------------------------
                  ; test the fat entry for reserved or bad sector
                  LDA FAT32_FAT_Next_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$0FFF ; the 4 MSB are not used in the FAT32
                  CMP #$0FFF
                  BNE IFAT32_READ_LIKED_FAT_ENTRY___TEST_NULL_VALUE
                  LDA FAT32_FAT_Next_Entry ; test for EOC (End Of Cluster)
                  AND #$FFF0
                  CMP #$FFF0
                  BNE IFAT32_READ_LIKED_FAT_ENTRY___TEST_NULL_VALUE
                  LDA FAT32_FAT_Next_Entry ; the cluster entry is not usable or its the last in the chaine
                  AND #$000F
                  CMP #8
                  BMI IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_RESERVED_OR_BAD
                  LDA #-1 ; end of the file
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___EOC
IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_RESERVED_OR_BAD
                  CMP #7
                  BNE IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_RESERVED
                  LDA #-2 ; Bad sector
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___EXIT
IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_RESERVED
                  LDA #-3 ; reserved sector
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___EXIT
                  LDA FAT32_FAT_Next_Entry ; test for EOC (End Of Cluster)
IFAT32_READ_LIKED_FAT_ENTRY___TEST_NULL_VALUE
                  CMP #0
                  BNE IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA FAT32_FAT_Next_Entry + 2 ; test for EOC (End Of Cluster)
                  CMP #0
                  BNE IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA #-4 ; empty sector
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___EXIT
                  ;-------------------------------------------------------------
                  ; the fat entry is containning data, now decrementing the
                  ; linked counter  to see if we need looking to the next fat entry
IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA FAT32_FAT_Linked_Entry
                  DEC A
                  BMI IFAT32_READ_LIKED_FAT_ENTRY___UNDERFLOW
                  STA FAT32_FAT_Entry ; update the low part the the fat entry we want to read
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___READ_NEXT_FAT
IFAT32_READ_LIKED_FAT_ENTRY___UNDERFLOW
                  LDA FAT32_FAT_Linked_Entry+2
                  DEC A
                  BMI IFAT32_READ_LIKED_FAT_ENTRY___WENT_THRW_ALL_FAT_LINKED
                  STA FAT32_FAT_Entry+2
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___READ_NEXT_FAT
IFAT32_READ_LIKED_FAT_ENTRY___WENT_THRW_ALL_FAT_LINKED
                  LDA #1
IFAT32_READ_LIKED_FAT_ENTRY___EOC
IFAT32_READ_LIKED_FAT_ENTRY___EXIT
                  PLX
PHX
PHA
LDX #<>TEXT_____DEBUG______FAT_L_OUT
LDA #`TEXT_____DEBUG______FAT_L_OUT
JSL IPUTS_ABS       ; print the first line
PLA
PLX
                  RTL
;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the root directory entry to read
;
;
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_ENTRY
                  setaxl
                  PHA
;----- debug -----
PHA
LDA #'r'
JSL IPUTC
LDA #$0D
JSL IPUTC
PLA
;-----------------
                  ; Set the curent folder cluster index to the ROOT FOLDER sector
                  ; ofset to point to the root directory ofset in the fat
                  ; I need to find the exact way to get this ofset
                  LDA FAT32_Root_Sector_offset
                  STA FAT32_Curent_Folder_start_cluster
                  LDA FAT32_Root_Sector_offset+2
                  STA FAT32_Curent_Folder_start_cluster+2
                  PLA
                  ;-------------------------------------------------------------
IFAT32_GET_FOLDER_ENTRY
                  ;-------------------------------------------------------------
                  setaxl
                  PHX
                  PHA ; Save the root entry index we want to read
;----- debug -----
PHX
PHA
LDX #<>TEXT_____DEBUG_FOLDER_ENTRY_TO_READ
LDA #`TEXT_____DEBUG_FOLDER_ENTRY_TO_READ
JSL IPUTS_ABS       ; print the first line
PLA
PHA
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA #$0D
JSL IPUTC
PLA
PHA
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
PLA
PLX
;------------------
                  LDX #0 ; compute in witch sector the desired root entry is, 16 entry per sector so we just need to divid the sector size by 16
IFAT32_GET_FOLDER_ENTRY__16_DIV:
                  LSR
                  INC X
                  CPX #4 ; divide by 16
                  BNE IFAT32_GET_FOLDER_ENTRY__16_DIV
                  CMP #0
                  BEQ IFAT32_GET_ROOT_ENTRY__LOAD_CURENT_BASE_SECTOR ; the entry is in the first folder cluster
                  ;-------------------------------------------------------------
                  ; the entry is bigger than 16, so we need to search for the entry cluster linked to the folder
                  STA FAT32_FAT_Linked_Entry ; store the number of sector from the base sector we need to read
                  LDA #0 ; entry index is 16 bit only so that limit at max 65535 entry per folder
                  STA FAT32_FAT_Linked_Entry+2
                  LDA FAT32_Curent_Folder_start_cluster ;FAT32_Root_Base_Sector
                  STA FAT32_FAT_Entry
                  LDA FAT32_Curent_Folder_start_cluster+2; FAT32_Root_Base_Sector +2
                  STA FAT32_FAT_Entry + 2
;----- debug -----
PHA
LDA #'v'
JSL IPUTC
PLA
;-----------------

                  JSL IFAT32_READ_LIKED_FAT_ENTRY
;----- debug -----
LDA #1
STA debug_stop
; ----------------
                  ;JSL FAT32_Print_FAT_STATE
                  ;-------------------- Test for fat validity ------------------
                  LDA FAT32_FAT_Next_Entry
                  CMP #0
                  BMI IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_temp_1
                  BRA IFAT32_GET_ROOT_ENTRY__LOAD_SECTOR ; the entry is not null so keep going
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_temp_1:
                  LDA FAT32_FAT_Next_Entry+2
                  CMP #0
                  BMI IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_4
                  BRA IFAT32_GET_ROOT_ENTRY__LOAD_SECTOR ; the entry is not null so keep going
                  ;-------------------------------------------------------------
IFAT32_GET_ROOT_ENTRY__LOAD_CURENT_BASE_SECTOR: ; set the cluster we want to read from the disc
                  LDA FAT32_Curent_Folder_start_cluster
                  STA FAT32_FAT_Next_Entry
                  LDA FAT32_Curent_Folder_start_cluster+2
                  STA FAT32_FAT_Next_Entry+2
IFAT32_GET_ROOT_ENTRY__LOAD_SECTOR:
                  ;-------------------------------------------------------------
                  ;------- From here we have the sector to read from the FAT point of vue -----
                  ;-------------------------------------------------------------
;----- debug -----
PHX
PHA
LDX #<>TEXT_____DEBUG_____________
LDA #`TEXT_____DEBUG_____________
JSL IPUTS_ABS       ; print the first line
LDX #<>TEXT_FAT32___FAT_Next_Entry
LDA #`TEXT_FAT32___FAT_Next_Entry
JSL IPUTS_ABS       ; print the first line
LDA FAT32_FAT_Next_Entry+2
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA FAT32_FAT_Next_Entry
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
PLA
PLX
; ----------------
;----- debug -----
PHX
PHA
LDX #<>TEXT_FAT32___Root_Base_Sector
LDA #`TEXT_FAT32___Root_Base_Sector
JSL IPUTS_ABS       ; print the first line
LDA FAT32_Root_Base_Sector+2
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA FAT32_Root_Base_Sector
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
PLA
PLX
;----- debug -----
BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_4_keep_prog
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_4: BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_3
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_4_keep_prog
; ----------------
; ----------------
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

;----- debug -----
BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_3_keep_prog
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_3: BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_2
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_3_keep_prog
; ----------------
;----- debug -----
PHX
PHA
LDX #<>TEXT_____DEBUG_SECTOR_TO_READ
LDA #`TEXT_____DEBUG_SECTOR_TO_READ
JSL IPUTS_ABS       ; print the first line
LDA ADDER_R+2
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA ADDER_R
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA #$0D
JSL IPUTC
PLA
PLX
; ----------------
                  ;---------------------------------------
                  ; test if the sector is alreaddy loaddes in RAM
                  LDA ADDER_R
                  CMP FAT32_Curent_Folder_Sector_loaded_in_ram
                  BNE IFAT32_GET_ROOT_ENTRY__NEED_TO_LOAD_A_NEW_SECTOR
                  LDA ADDER_R+2
                  CMP FAT32_Curent_Folder_Sector_loaded_in_ram+2
                  BNE IFAT32_GET_ROOT_ENTRY__NEED_TO_LOAD_A_NEW_SECTOR
                  BEQ FAT32_FDD_SECTOR_ALREADDY_LOADDED_IN_RAM
;----- debug -----
BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_2_keep_prog
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_2: BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_1
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_2_keep_prog:
;-----------------
IFAT32_GET_ROOT_ENTRY__NEED_TO_LOAD_A_NEW_SECTOR:
                  LDA ADDER_R+2
                  STA FAT32_Curent_Folder_Sector_loaded_in_ram+2 ; save the new sector to load
                  LDA ADDER_R
                  STA FAT32_Curent_Folder_Sector_loaded_in_ram
;----- debug -----
PHX
PHA
LDX #<>TEXT_FAT32___Curent_Folder_Sector_loaded_in_ram
LDA #`TEXT_FAT32___Curent_Folder_Sector_loaded_in_ram
JSL IPUTS_ABS       ; print the first line
LDA FAT32_Curent_Folder_Sector_loaded_in_ram+2
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA FAT32_Curent_Folder_Sector_loaded_in_ram
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA #$0D
JSL IPUTC
PLA
PLX
; ----------------
                  LDA #`FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Curent_Folder_Sector_loaded_in_ram+2 ; Get the ROOT directory sector to read
                  TAX
                  LDA FAT32_Curent_Folder_Sector_loaded_in_ram
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX
;----- debug -----
BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_1_keep_prog
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_1: BRA IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED_1_keep_prog:
;LDA debug_stop
;CMP #0
;BEQ FAT32_FDD_SECTOR_ALREADDY_LOADDED_IN_RAM
;LDX #<>TEXT_____BREAK
;LDA #`TEXT_____BREAK
;JSL IPUTS_ABS       ; print the first line
;debug_ihfgjksbdfljgbsljfgb: BRA debug_ihfgjksbdfljgbsljfgb
;-----------------
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
                  LDA #<>FAT32_Curent_Folder_entry_value
                  TAY
                  LDA #31
                  MVN `FAT32_FOLDER_ADDRESS_BUFFER_512, `FAT32_Curent_Folder_entry_value
                  BRA IFAT32_GET_ROOT_ENTRY___EXIT_OK
IFAT32_GET_ROOT_ENTRY__ERROR_RETURNED:
                  PLX
IFAT32_GET_ROOT_ENTRY___EXIT_OK
PHX
PHA
LDX #<>TEXT_____DEBUG____________EX
LDA #`TEXT_____DEBUG____________EX
JSL IPUTS_ABS       ; print the first line
PLA
PLX
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
; Get in FAT32_FAT_Entry the FAT entry where to get the next One
; return the next fat entry to read  in FAT32_FAT_Next_Entry
;
; JSL IFAT32_GET_ROOT_ENTRY
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

;----- debug -----
PHX
PHA
LDX #<>TEXT_FAT32___FAT_Entry
LDA #`TEXT_FAT32___FAT_Entry
JSL IPUTS_ABS       ; print the first line
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
LDA #$0D
JSL IPUTC
PLA
PLX
; ----------------
                  ; find in witch sector the fat entry is suposed to be
                  ;------- Test id the FAT entry is in the first cluster -------
                  LDA FAT32_FAT_Entry+2
                  CMP #0
                  BNE FAT32_FAT_ENTRY_FIND_THE_CLUSTER ; the FAT entry is definitly not in the first FAT cluster
                  STA FAT32_FAT_Next_Entry+2
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  STA FAT32_FAT_Next_Entry
                  CMP #0
                  BNE FAT32_FAT_ENTRY_FIND_THE_CLUSTER
                  BRA FAT32_ENTRY_SECTOR_LOCATION_FIND ; if this part of the code is riched, its mean that the FAT entry requested is with in the first FAT clustrer (entry smaller than 16)
FAT32_FAT_ENTRY_FIND_THE_CLUSTER
                  ; ----- shift the 32 Byte FAT entry by 4 (divide by 16) ------
                  ;-------- to comput the FAT cluster to load in memory --------
                  LDA FAT32_FAT_Entry+2
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; comput the high part divided by 16
                  STA FAT32_FAT_Next_Entry+2 ; use FAT32_FAT_Next_Entry as a temporary variable
                  LDA FAT32_FAT_Entry+2 ;extract the 4 bits of the HIGHT part of FAT32_FAT_Entry to casrry them in the LOW part
                  AND #$F
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
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; divide the high part of the FAT entry requested by 16  because there is 16 FAt entry per sector
                  AND #$0FFF
                  ORA FAT32_FAT_Next_Entry
                  STA FAT32_FAT_Next_Entry ; Now contain the 32 bit FAT Cluster to load
FAT32_ENTRY_SECTOR_LOCATION_FIND:
;----- debug -----
PHX
PHA
LDX #<>TEXT_____DEBUG_FAT_SECTOR_TO_READ
LDA #`TEXT_____DEBUG_FAT_SECTOR_TO_READ
JSL IPUTS_ABS       ; print the first line
LDA FAT32_FAT_Next_Entry+2
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA FAT32_FAT_Next_Entry
XBA
JSL IPRINT_HEX
XBA
JSL IPRINT_HEX
LDA #$0D
JSL IPUTC
PLA
PLX
; ----------------
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
                  CMP FAT32_Curent_Folder_Sector_loaded_in_ram+2
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
                  AND #$0F ; get only the 7 first byte to get the ofset in the curent FAT cluster loades
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
; Test if the content of FAT32_FAT_Next_Entry is a usable sector o r not
;
; return value :
;  0  =>  sector contain valid data
; -1  =>  end of the file, no more sector
; -2  =>  bad sector
; -3  =>  reserved sector
;-------------------------------------------------------------------------------
FAT32_Test_Fat_Entry_Validity
                  PLA
                  LDA FAT32_FAT_Next_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$0FFF ; the 4 MSB are not used in the FAT32
                  CMP #$0FFF
                  BNE FAT32_Test_Fat_Entry_Validity___TEST_NULL_VALUE
                  LDA FAT32_FAT_Next_Entry ; test for EOC (End Of Cluster)
                  AND #$FFF0
                  CMP #$FFF0
                  BNE FAT32_Test_Fat_Entry_Validity___TEST_NULL_VALUE
                  LDA FAT32_FAT_Next_Entry ; the cluster entry is not usable or its the last in the chaine
                  AND #$000F
                  CMP #8
                  BMI FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED_OR_BAD
                  LDA #-1 ; end of the file
                  BRA FAT32_Test_Fat_Entry_Validity___EXIT
FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED_OR_BAD
                  CMP #7
                  BNE FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED
                  LDA #-2 ; Bad sector
                  BRA FAT32_Test_Fat_Entry_Validity___EXIT
FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED
                  LDA #-3 ; reserved sector
                  BRA FAT32_Test_Fat_Entry_Validity___EXIT
                  LDA FAT32_FAT_Next_Entry ; test for EOC (End Of Cluster)
FAT32_Test_Fat_Entry_Validity___TEST_NULL_VALUE
                  CMP #0
                  BNE FAT32_Test_Fat_Entry_Validity___EXIT
                  LDA FAT32_FAT_Next_Entry + 2 ; test for EOC (End Of Cluster)
                  CMP #0
                  BNE FAT32_Test_Fat_Entry_Validity___EXIT
                  LDA #-4 ; empty sector
FAT32_Test_Fat_Entry_Validity___EXIT
                  PHA
                  RTL
                  ;-------------------------------------------------------------
;-------------------------------------------------------------------------------
; Search for the file name in the root directory
; Stack 0-1-3-4 pointer to the file name strings to load
; Stack 5-6-7-8 buffer where to load the file
;-------------------------------------------------------------------------------
FAT32_ILOAD_FILE
                  JSL IFAT32_READ_BOOT_SECTOR
                  CMP #$0001
                  BEQ ILOAD_FILE_FAT_32_BOOT_SECTOR_PARSING_OK
                  LDA #-1
                  BRA FAT32_ILOAD_FILE_RETURN_ERROR_temp
ILOAD_FILE_FAT_32_BOOT_SECTOR_PARSING_OK
                  JSL IFAT32_COMPUT_ROOT_DIR_POS
                  setaxl
                  LDA #$00 ; sellect the first entry
                  PHA
FAT32_ILOAD_FILE_READ_NEXT_ROOT_ENTRY
                  JSL IFAT32_GET_ROOT_ENTRY
                  LDA FAT32_Curent_Folder_entry_value + 11 ; get the flag Byte to test if it a file or a directory
                  AND #$10
                  CMP #$10
                  BNE FAT32_ILOAD_FILE_ENTRY ; if equal we read a directory so just read the next one
;;;;FAT32_ILOAD_FILE_STRING_NOT_MATCHED removed as we still need to test what type of entry it is befor trying to compare the file name
                  PLA   ; get the actual root entry
                  CMP FAT32_Max_Root_Entry ; prevent to loop forever so exit
                  BEQ FAT32_ILOAD_FILE_NO_FILE_MATCHED
                  INC A ; sellect the next root entry
                  PHA   ; save the next root entry to read
                  BRA FAT32_ILOAD_FILE_READ_NEXT_ROOT_ENTRY
FAT32_ILOAD_FILE_ENTRY
                  setaxl
                  PLA   ; get the actual root entry
                  CMP FAT32_Max_Root_Entry ; prevent to loop forever so exit
                  BEQ FAT32_ILOAD_FILE_NO_FILE_MATCHED
                  INC A ; sellect the next root entry in case the file name is wrong
                  PHA   ; save the next root entry to read

                  ; copare the file name we want to load and the root entry file name
                  LDX #-1
                  LDY #-1
FAT32_ILOAD_FILE_CHAR_MATCHING
                  INC X
                  INC Y
                  CPX #11 ; FAT12 file or folder size
                  BEQ FAT32_ILOAD_FILE_STRING_MATCHED
                  LDA (6,S),Y ; load the "y" char file name we want to read
                  CMP FAT32_Curent_Folder_entry_value,X
                  BEQ FAT32_ILOAD_FILE_CHAR_MATCHING
                  BRA FAT32_ILOAD_FILE_READ_NEXT_ROOT_ENTRY ;;; FAT32_ILOAD_FILE_STRING_NOT_MATCHED    emoved as we still need to test what type of entry it is befor trying to compare the file name
FAT32_ILOAD_FILE_NO_FILE_MATCHED
                  PLA
                  LDA #-2
FAT32_ILOAD_FILE_RETURN_ERROR_temp
                  BRA FAT32_ILOAD_FILE_RETURN_ERROR
FAT32_ILOAD_FILE_STRING_MATCHED
                  PLA
                  LDA FAT32_Curent_Folder_entry_value + 26 ; get the first fat entry for the fil from the root directory entry we matched
                  STA FAT32_FAT_Next_Entry

FAT32_ILOAD_FILE_Read_next_sector; read sector function to call there
                  ;LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  ;PHA
                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  ;PHA
                  LDA 10,S ; load the byte nb 3 (bank byte)
                  PHA
                  LDA 12,S ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Next_Entry ; sector to read
                  ADC #1+9+9+14 ; skip the reserved sector(MBR?) ,  the 2 fat and the root sector that will need to be computed  acording to the fat position if several partition are in the same hardrive, it for now hardcoded as one partition
                  LDX #0
                  JSL IFAT_READ_SECTOR
                  PLX
                  PLX
                  ; point to the next 512 byte in the buffer
                  LDA 12,S ; load the low world part of the buffer address
                  CLC
                  LDA #0
                  PHA ; save the cpt vale
                  PHA ; save the
FAT32_ILOAD_FILE_Add_More_Sector_Per_Cluster
                  LDA 4,S ; load the Byte per cluster value
                  ADC FAT32_Byte_Per_Sector
                  STA 4,S
                  LDA FAT32_Sector_Per_Cluster
                  CMP 2,S
                  BEQ FAT32_ILOAD_FILE_Read_Next_Data
                  LDA 2,S
                  INC A
                  STA 2,S
                  BRA FAT32_ILOAD_FILE_Add_More_Sector_Per_Cluster
FAT32_ILOAD_FILE_Read_Next_Data
                  PLX ; removing the compter valuer from the stack
                  ;-------------------------------------------------------------
                  ; compute the next buffer address to use to copy file
                  LDA 14,S ; load the low world part of the buffer address
                  CLC
                  ADC 2,S
                  BCC FAT32_ILOAD_FILE_New_Buffer_Address_computed
                  STA 14,S ; Save the low world part of the buffer address
                  LDA 12,S ; load the byte nb 3 (bank byte)
                  ADC #1
                  STA 12,S ; Save the byte nb 3 (bank byte)
FAT32_ILOAD_FILE_New_Buffer_Address_computed
                  PLX ; get the Byte per cluster count out of the stack
                  ;-------------------------------------------------------------
                  LDA FAT32_FAT_Next_Entry ; sector to read
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  LDA FAT32_FAT_Next_Entry
                  CMP #$FFE
                  BCS FAT32_ILOAD_FILE_END_OF_FILE
                  BRA FAT32_ILOAD_FILE_Read_next_sector
FAT32_ILOAD_FILE_END_OF_FILE
FAT32_ILOAD_FILE_RETURN_ERROR
                  RTL

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

FOENIX_SD_INIT_READ
                LDA #$01
                STA SDC_TRANS_TYPE_REG  ; Set Init SD

                LDA #$01
                STA SDC_TRANS_CONTROL_REG ; Let's Start the Process

SDC_NOT_FINISHED
                LDA SDC_TRANS_STATUS_REG
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ SDC_NOT_FINISHED
                LDA SDC_TRANS_ERROR_REG
                STA $001000
                JSL IPRINT_HEX
                CMP #$00
                BNE SDISREADY
                LDA GABE_MSTR_CTRL
                AND #~GABE_CTRL_SDC_LED
                ORA GABE_CTRL_SDC_LED
                STA GABE_MSTR_CTRL

SDISREADY
                LDA #$00
                STA SDC_SD_ADDR_7_0_REG
                LDA #$00
                STA SDC_SD_ADDR_15_8_REG
                LDA #$00
                STA SDC_SD_ADDR_23_16_REG
                LDA #$00
                STA SDC_SD_ADDR_31_24_REG

                LDA #SDC_TRANS_READ_BLK
                STA SDC_TRANS_TYPE_REG

                LDA #$01
                STA SDC_TRANS_CONTROL_REG ; Let's Start the Process

SDC_NOT_FINISHED2
                LDA SDC_TRANS_STATUS_REG
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ SDC_NOT_FINISHED2

                LDA SDC_TRANS_ERROR_REG
                STA $001001

                LDA SDC_RX_FIFO_DATA_CNT_LO
                STA $001002
                JSL IPRINT_HEX
                LDA SDC_RX_FIFO_DATA_CNT_HI
                STA $001003
                JSL IPRINT_HEX
                LDA #$0D
                JSL IPUTC
                LDX #$0000
                LDA #$0D
                JSL IPUTC
SDC_LOAD_BLOCK
                LDA SDC_RX_FIFO_DATA_REG
                JSL IPRINT_HEX
                ;STA SD_BLK_BEGIN, X
                INX
                CPX #$0200
                BNE SDC_LOAD_BLOCK
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

; sector index :  A
ISD_READ        ;PHP
                setaxl
;PHA
;PHX
;LDA #$0D
;JSL IPUTC
;PLX
;PLA
PHA
TXA ; print X (MSB)
XBA
JSL IPRINT_HEX ; print the sector
XBA
JSL IPRINT_HEX ; print the sector
PLA
XBA ; print A (LSB)
JSL IPRINT_HEX ; print the sector
XBA
JSL IPRINT_HEX ; print the sector

                ASL ;get the 512 byte ofset from the sector index
                BCC ISD_READ__NO_OVERFLOW
                PHA
                TXA
                ASL
                CLC
                ADC #1
                TAX
                PLA
ISD_READ__NO_OVERFLOW:

PHA
LDA #' '
JSL IPUTC
TXA
XBA
JSL IPRINT_HEX ; print the sector
XBA
JSL IPRINT_HEX ; print the sector
PLA
XBA
JSL IPRINT_HEX ; print the sector
XBA
JSL IPRINT_HEX ; print the sector
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

                PHA
                LDA #' '
                JSL IPUTC
                LDA #'E'
                JSL IPUTC
                PLA
                PHA
                JSL IPRINT_HEX
                LDA #' '
                JSL IPUTC
                LDA #'B'
                JSL IPUTC
                LDA #' '
                JSL IPUTC
                PLA

                CMP #0
                BNE ISD_READ__INIT_RETURN
ISD_READ_GET_BYTE_COUNT:
                LDA SDC_RX_FIFO_DATA_CNT_HI ; get the number of byte in the fifo
                JSL IPRINT_HEX
                LDA SDC_RX_FIFO_DATA_CNT_LO ; get the number of byte in the fifo
                JSL IPRINT_HEX
                LDA #$0D
                JSL IPUTC


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
                setal
                ;LDA #$0D
                ;JSL IPUTC
                ;LDA #$0D
                ;JSL IPUTC



                LDX #0
ISD_READ__READ_LOOP_BYTE:
                LDA SDC_RX_FIFO_DATA_REG
ISD_READ_       STA @l FAT32_DATA_ADDRESS_BUFFER_512,x
                JSL IPRINT_HEX
                INX
                CPX #$200
                BNE ISD_READ__READ_LOOP_BYTE
ISD_READ__INIT_RETURN:
                LDA #1
                STA SDC_RX_FIFO_CTRL_REG ; discard all possible other byt

                LDA #$0D
                JSL IPUTC
                LDA #'-'
                JSL IPUTC
                setaxl
                ;PLA
                ;PLP
                RTL
;----------------------------------------------------------------------------------------------------------
;
;----------------------------------------------------------------------------------------------------------

FAT32_Print_FAT_STATE
                PHP
                PHA
                PHX
                PHY
                LDX #<>TEXT_FAT32___Byte_Per_Sector
                LDA #`TEXT_FAT32___Byte_Per_Sector
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Byte_Per_Sector
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Sector_Per_Cluster
                LDA #`TEXT_FAT32___Sector_Per_Cluster
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Sector_Per_Cluster
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Nb_Of_reserved_Cluster
                LDA #`TEXT_FAT32___Nb_Of_reserved_Cluster
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Nb_Of_reserved_Cluster
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Nb_Of_FAT
                LDA #`TEXT_FAT32___Nb_Of_FAT
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Nb_Of_FAT
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Max_Root_Entry
                LDA #`TEXT_FAT32___Max_Root_Entry
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Max_Root_Entry
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Total_Sector_Count
                LDA #`TEXT_FAT32___Total_Sector_Count
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Total_Sector_Count
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Sector_per_Fat
                LDA #`TEXT_FAT32___Sector_per_Fat
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Sector_per_Fat+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Sector_per_Fat
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Sector_per_Track
                LDA #`TEXT_FAT32___Sector_per_Track
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Sector_per_Track
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Nb_of_Head
                LDA #`TEXT_FAT32___Nb_of_Head
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Nb_of_Head
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Nb_Of_Sector_In_Partition
                LDA #`TEXT_FAT32___Nb_Of_Sector_In_Partition
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Nb_Of_Sector_In_Partition+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Nb_Of_Sector_In_Partition
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Boot_Signature
                LDA #`TEXT_FAT32___Boot_Signature
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Boot_Signature
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Volume_ID
                LDA #`TEXT_FAT32___Volume_ID
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Volume_ID+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Volume_ID
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Volume_Label
                LDA #`TEXT_FAT32___Volume_Label
                JSL IPUTS_ABS       ; print the first line
                LDX #0
PRINT_FAT32_Volume_Label:
                LDA @l FAT32_Volume_Label,x
                JSL IPUTC
                INX
                CPX #11
                BNE PRINT_FAT32_Volume_Label
                LDX #<>TEXT_FAT32___File_System_Type
                LDA #`TEXT_FAT32___File_System_Type
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_File_System_Type
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Sector_loaded_in_ram
                LDA #`TEXT_FAT32___Sector_loaded_in_ram
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Sector_loaded_in_ram+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Sector_loaded_in_ram
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Root_Sector_offset
                LDA #`TEXT_FAT32___Root_Sector_offset
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Root_Sector_offset+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Root_Sector_offset
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Root_Base_Sector
                LDA #`TEXT_FAT32___Root_Base_Sector
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Root_Base_Sector+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Root_Base_Sector
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Curent_Folder_Sector_loaded_in_ram
                LDA #`TEXT_FAT32___Curent_Folder_Sector_loaded_in_ram
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Curent_Folder_Sector_loaded_in_ram+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Curent_Folder_Sector_loaded_in_ram
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Curent_Folder_entry_value
                LDA #`TEXT_FAT32___Curent_Folder_entry_value
                JSL IPUTS_ABS       ; print the first line
                LDA #$0D
                JSL IPUTC
                LDX #0
PRINT_FAT32_Root_entry_value:
                LDA @l FAT32_Curent_Folder_entry_value,x
                JSL IPRINT_HEX
                INX
                CPX #32
                BNE PRINT_FAT32_Root_entry_value
                LDA #$0D
                JSL IPUTC
                LDX #0
PRINT_FAT32_Root_entry_value_ASCII:
                LDA @l FAT32_Curent_Folder_entry_value,x
                JSL IPUTC
                INX
                CPX #32
                BNE PRINT_FAT32_Root_entry_value_ASCII
                LDX #<>TEXT_FAT32___FAT_Base_Sector
                LDA #`TEXT_FAT32___FAT_Base_Sector
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_FAT_Base_Sector+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_FAT_Base_Sector
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___FAT_Sector_loaded_in_ram
                LDA #`TEXT_FAT32___FAT_Sector_loaded_in_ram
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_FAT_Sector_loaded_in_ram+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_FAT_Sector_loaded_in_ram
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___FAT_Entry
                LDA #`TEXT_FAT32___FAT_Entry
                JSL IPUTS_ABS       ; print the first line
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
                LDX #<>TEXT_FAT32___FAT_Next_Entry
                LDA #`TEXT_FAT32___FAT_Next_Entry
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_FAT_Next_Entry+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_FAT_Next_Entry
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___FAT_Linked_Entry
                LDA #`TEXT_FAT32___FAT_Linked_Entry
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_FAT_Linked_Entry+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_FAT_Linked_Entry
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Data_Base_Sector
                LDA #`TEXT_FAT32___Data_Base_Sector
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Data_Base_Sector+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Data_Base_Sector
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___MBR_Partition_address
                LDA #`TEXT_FAT32___MBR_Partition_address
                JSL IPUTS_ABS       ; print the first line
                LDA MBR_Partition_address+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA MBR_Partition_address
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Curent_Folder_base_cluster
                LDA #`TEXT_FAT32___Curent_Folder_base_cluster
                JSL IPUTS_ABS       ; print the first line
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
                LDX #<>TEXT_FAT32___Curent_Folder_curent_cluster
                LDA #`TEXT_FAT32___Curent_Folder_curent_cluster
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Curent_Folder_curent_cluster+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Curent_Folder_curent_cluster
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Curent_File_base_cluster
                LDA #`TEXT_FAT32___Curent_File_base_cluster
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Curent_File_base_cluster+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Curent_File_base_cluster
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Curent_File_curent_cluster
                LDA #`TEXT_FAT32___Curent_File_curent_cluster
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Curent_File_curent_cluster+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Curent_File_curent_cluster
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___Sector_to_read
                LDA #`TEXT_FAT32___Sector_to_read
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_Sector_to_read+2
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDA FAT32_Sector_to_read
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                LDX #<>TEXT_FAT32___SD_FDD_HDD_Sell
                LDA #`TEXT_FAT32___SD_FDD_HDD_Sell
                JSL IPUTS_ABS       ; print the first line
                LDA FAT32_SD_FDD_HDD_Sell
                XBA
                JSL IPRINT_HEX
                XBA
                JSL IPRINT_HEX
                PLY
                PLX
                PLA
                PLP
                RTL


;----------------------------------------------------------------------------------------------------------
; EOF
;----------------------------------------------------------------------------------------------------------

* = $20425
Partition_ofset_text    .text "Partition ofset (in cluster) : ",0

TEXT_FAT32___Byte_Per_Sector		         .text   $0D, "FAT32 Byte Per Sector              ",0
TEXT_FAT32___Sector_Per_Cluster          .text   $0D, "FAT32 Sector Per Cluster           ",0
TEXT_FAT32___Nb_Of_reserved_Cluster      .text   $0D, "FAT32 Nb Of reserved Cluster       ",0
TEXT_FAT32___Nb_Of_FAT                   .text   $0D, "FAT32 Nb Of FAT                    ",0
TEXT_FAT32___Max_Root_Entry              .text   $0D, "FAT32 Max Root Entry               ",0
TEXT_FAT32___Total_Sector_Count          .text   $0D, "FAT32 Total_Sector_Count           ",0
TEXT_FAT32___Sector_per_Fat              .text   $0D, "FAT32 Sector per Fat               ",0
TEXT_FAT32___Sector_per_Track            .text   $0D, "FAT32 Sector per Track             ",0
TEXT_FAT32___Nb_of_Head                  .text   $0D, "FAT32 Nb of Head                   ",0
TEXT_FAT32___Nb_Of_Sector_In_Partition   .text   $0D, "FAT32 Nb Of Sector In Partition    ",0
TEXT_FAT32___Boot_Signature              .text   $0D, "FAT32 Boot Signature               ",0
TEXT_FAT32___Volume_ID                   .text   $0D, "FAT32 Volume ID                    ",0
TEXT_FAT32___Volume_Label                .text   $0D, "FAT32 Volume Label                 ",0
TEXT_FAT32___File_System_Type            .text   $0D, "FAT32 File System Type             ",0
TEXT_FAT32___Sector_loaded_in_ram        .text   $0D, "FAT32 Sector loaded in ram         ",0
TEXT_FAT32___Root_Sector_offset          .text   $0D, "FAT32 Root Sector offset           ",0
TEXT_FAT32___Root_Base_Sector            .text   $0D, "FAT32 Root Base Sector             ",0
TEXT_FAT32___Curent_Folder_Sector_loaded_in_ram   .text   $0D, "FAT32 Folder Sector loaded in ram  ",0
TEXT_FAT32___Curent_Folder_entry_value            .text   $0D, "FAT32 Folder entry value            ",0
TEXT_FAT32___FAT_Base_Sector             .text   $0D, "FAT32 FAT Base Sector              ",0
TEXT_FAT32___FAT_Sector_loaded_in_ram    .text   $0D, "FAT32 FAT Sector loaded in ram     ",0
TEXT_FAT32___FAT_Entry                   .text   $0D, "FAT32 FAT Entry                    ",0
TEXT_FAT32___FAT_Next_Entry              .text   $0D, "FAT32 FAT Next Entry               ",0
TEXT_FAT32___FAT_Linked_Entry            .text   $0D, "FAT32 FAT Linked Entry             ",0
TEXT_FAT32___Data_Base_Sector            .text   $0D, "FAT32 Data Base Sector             ",0
TEXT_FAT32___MBR_Partition_address       .text   $0D, "MBR Partition address              ",0
TEXT_FAT32___Curent_Folder_base_cluster   .text   $0D, "FAT32 Curent Folder base cluster   ",0
TEXT_FAT32___Curent_Folder_curent_cluster .text   $0D, "FAT32 Curent Folder curent cluster ",0
TEXT_FAT32___Curent_File_base_cluster    .text   $0D, "FAT32 Curent File base cluster     ",0
TEXT_FAT32___Curent_File_curent_cluster  .text   $0D, "FAT32 Curent File curent cluster   ",0
TEXT_FAT32___Sector_to_read              .text   $0D, "FAT32 Sector to read               ",0
TEXT_FAT32___SD_FDD_HDD_Sell             .text   $0D, "FAT32 SD_FDD_HDD_Sell              ",0
TEXT_____Fat_size                        .text   $0D, "Fat_size                           ",0

TEXT_____DEBUG                           .text   $0D, "DEBUG                              ",0
TEXT_____BREAK                           .text   $0D, "BREAK                              ",0
TEXT_____DEBUG_FOLDER_ENTRY_TO_READ      .text   $0D, "DEBUG  Folder Entry To Read        ",0
TEXT_____DEBUG_FAT_SECTOR_TO_READ        .text   $0D, "DEBUG  FAT Sector To Read          ",0
TEXT_____DEBUG_SECTOR_TO_READ            .text   $0D, "DEBUG  SECTOR_TO_READ              ",0
TEXT_____DEBUG______FAT_L_IN             .text   $0D, "*********** FAT L IN **************",$0D,0
TEXT_____DEBUG______FAT_L_OUT            .text   $0D, "----------- FAT L OUT -------------",$0D,0
TEXT_____DEBUG_____________              .text   $0D, "*********** FOLDER IN *************",$0D,0
TEXT_____DEBUG____________EX             .text   $0D, "----------- FOLDER OUT ------------",$0D,0
TEXT_____DEBUG_END_LS                    .text   $0D, "___________ END LS CMD ____________",$0D,0

* = $120000
.include "HDD_row_TEXT_HEX.asm"
