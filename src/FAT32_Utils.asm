.cpu "65816"

;-------------------------------------------------------------------------------
;
; Test the folder entry type
;
; The folder entry is read by JSL IFAT32_GET_ROOT_ENTRY,  A is containing the
; folder entry to read
;
; out A
; $00 -> Last folder entry in the curent folder, can be used for new file
; $01 -> file entry
; $08 -> Volume name entry, only present on the first entry of the root directory
; $0F -> Long FileName entry
; $10 -> folder entry
; $E5 -> deleted entry, can be used for new file
;-------------------------------------------------------------------------------
FAT32_GET_FOLDER_ENTRY_TYPE
                  LDA FAT32_Curent_Directory_entry_value
                  AND #$00FF
                  CMP #$E5 ; test if the entry is deleted
                  BEQ FAT32_GET_FOLDER_ENTRY_TYPE__DELETED_ENTRY
                  CMP #$00 ; test if we reached the last entry in the folder
                  BEQ FAT32_GET_FOLDER_ENTRY_TYPE__LAST_ENTRY_IN_FOLDER
                  LDA FAT32_Curent_Directory_entry_value +11
                  AND #$00FF
                  CMP #$0F ; test if it's a long name entry
                  BEQ FAT32_GET_FOLDER_ENTRY_TYPE__FLN
                  CMP #$08 ; test if it's a volum name
                  BEQ FAT32_GET_FOLDER_ENTRY_TYPE__VOLUM_NAME
                  AND #$10
                  CMP #$10 ;CMP #$20 ; if different from 0x20 its nor a file name entry (need to confirm that)
                  BEQ FAT32_GET_FOLDER_ENTRY_TYPE__Folder
                  LDA #$01
                  BRA FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY
 FAT32_GET_FOLDER_ENTRY_TYPE__FLN:
                  LDA #$0F
                  BRA FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY
 FAT32_GET_FOLDER_ENTRY_TYPE__VOLUM_NAME:
                  LDA #$08
                  BRA FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY
 FAT32_GET_FOLDER_ENTRY_TYPE__Folder:
                  LDA #$10
                  BRA FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY
 FAT32_GET_FOLDER_ENTRY_TYPE__DELETED_ENTRY:
                  LDA #$E5
                  BRA FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY
 FAT32_GET_FOLDER_ENTRY_TYPE__LAST_ENTRY_IN_FOLDER:
                  LDA #$00
                  BRA FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY
 FAT32_GET_FOLDER_ENTRY_TYPE__FILE_ENTRY:
                  RTL
;-------------------------------------------------------------------------------
;----------- comput the real sector ofset of the curent fat entry --------------
;-------------------------------------------------------------------------------
FAT32_COMPUT_PHISICAL_CLUSTER
                  PHA
                  ; first operand
                  LDA FAT32_FAT_Entry ;
                  STA ADDER_A
                  LDA FAT32_FAT_Entry+2
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

                  ; get the final result out of the hardware
                  LDA ADDER_R;
                  STA FAT32_FAT_Entry_Physical_Address
                  LDA ADDER_R+2
                  STA FAT32_FAT_Entry_Physical_Address+2
                  PLA
                  RTL

;-------------------------------------------------------------------------------
;------------ comput the real sector ofset of the next fat entry ---------------
;-------------------------------------------------------------------------------
FAT32_COMPUT_PHISICAL_CLUSTER_NEXT
                  PHA
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

                  ; get the final result out of the hardware
                  LDA ADDER_R;
                  STA FAT32_FAT_Entry_PhisicalL_Address_next
                  LDA ADDER_R+2
                  STA FAT32_FAT_Entry_PhisicalL_Address_next+2
                  PLA
                  RTL
;-------------------------------------------------------------------------------
;
; Test if the content of FAT32_FAT_Next_Entry is a usable sector or not
;
; return value :
;  1  =>  sector contain valid data
; -1  =>  end of the file, no more sector
; -2  =>  bad sector
; -3  =>  reserved sector
; -4  =>  empty sector
;-------------------------------------------------------------------------------
FAT32_Test_Fat_Entry_Validity_Next
                  ;PLA
                  LDA FAT32_FAT_Next_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$0FFF ; the 4 MSB are not used in the FAT32
                  CMP #$0FFF
                  BNE FAT32_Test_Fat_Entry_Validity_Next___TEST_NULL_VALUE
                  LDA FAT32_FAT_Next_Entry ; test for EOC (End Of Cluster)
                  AND #$FFF0
                  CMP #$FFF0
                  BNE FAT32_Test_Fat_Entry_Validity_Next___TEST_NULL_VALUE
                  ;------------------------------------------------------
                  ; if reach there entry = 0xXFFFFFFX
                  LDA FAT32_FAT_Next_Entry ; the cluster entry is not usable or its the last in the chaine
                  AND #$000F
                  CMP #8
                  BMI FAT32_Test_Fat_Entry_Validity_Next___NEXT_CLUSTER_RESERVED_OR_BAD
                  LDA #-1 ; end of the file
                  BRA FAT32_Test_Fat_Entry_Validity_Next_ERROR_EXIT
 FAT32_Test_Fat_Entry_Validity_Next___NEXT_CLUSTER_RESERVED_OR_BAD
                  CMP #7
                  BNE FAT32_Test_Fat_Entry_Validity_Next___NEXT_CLUSTER_RESERVED
                  LDA #-2 ; Bad sector
                  BRA FAT32_Test_Fat_Entry_Validity_Next_ERROR_EXIT
 FAT32_Test_Fat_Entry_Validity_Next___NEXT_CLUSTER_RESERVED
                  LDA #-3 ; reserved sector
                  BRA FAT32_Test_Fat_Entry_Validity_Next_ERROR_EXIT
                  ;------------------------------------------------------
                  ; if  jump here, the cluster is at lest not reserved or bad
 FAT32_Test_Fat_Entry_Validity_Next___TEST_NULL_VALUE
                  LDA FAT32_FAT_Next_Entry ; test for EOC (End Of Cluster)
                  CMP #0
                  BNE FAT32_Test_Fat_Entry_Validity_Next___EXIT
                  LDA FAT32_FAT_Next_Entry + 2 ; test for EOC (End Of Cluster)
                  CMP #0
                  BNE FAT32_Test_Fat_Entry_Validity_Next___EXIT
                  LDA #-4 ; empty sector
                  BRA FAT32_Test_Fat_Entry_Validity_Next_ERROR_EXIT
 FAT32_Test_Fat_Entry_Validity_Next___EXIT:
                  LDA #1
 FAT32_Test_Fat_Entry_Validity_Next_ERROR_EXIT:
                  ;PHA
                  RTL
;-------------------------------------------------------------
;-------------------------------------------------------------------------------
;
; Test if the content of FAT32_FAT_Entry is a usable sector or not
;
; return value :
;  1  =>  sector contain valid data
; -1  =>  end of the file, no more sector
; -2  =>  bad sector
; -3  =>  reserved sector
;-------------------------------------------------------------------------------
FAT32_Test_Fat_Entry_Validity
                  ;PHA
                  LDA FAT32_FAT_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$0FFF ; the 4 MSB are not used in the FAT32
                  CMP #$0FFF
                  BNE FAT32_Test_Fat_Entry_Validity___TEST_NULL_VALUE
                  LDA FAT32_FAT_Entry ; test for EOC (End Of Cluster)
                  AND #$FFF0
                  CMP #$FFF0
                  BNE FAT32_Test_Fat_Entry_Validity___TEST_NULL_VALUE
                  ;------------------------------------------------------
                  ; if reach there entry = 0xXFFFFFFX
                  LDA FAT32_FAT_Entry ; the cluster entry is not usable or its the last in the chaine
                  AND #$000F
                  CMP #8
                  BMI FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED_OR_BAD
                  LDA #-1 ; end of the file
                  BRL FAT32_Test_Fat_Entry_Validity_ERROR_EXIT
                  FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED_OR_BAD
                  CMP #7
                  BNE FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED
                  LDA #-2 ; Bad sector
                  BRL FAT32_Test_Fat_Entry_Validity_ERROR_EXIT
                  FAT32_Test_Fat_Entry_Validity___NEXT_CLUSTER_RESERVED
                  LDA #-3 ; reserved sector
                  BRL FAT32_Test_Fat_Entry_Validity_ERROR_EXIT
                  ;------------------------------------------------------
                  ; if  jump here, the cluster is at lest not reserved or bad
                  FAT32_Test_Fat_Entry_Validity___TEST_NULL_VALUE
                  LDA FAT32_FAT_Entry ; test for EOC (End Of Cluster)
                  CMP #0
                  BNE FAT32_Test_Fat_Entry_Validity___EXIT
                  LDA FAT32_FAT_Entry + 2 ; test for EOC (End Of Cluster)
                  CMP #0
                  BNE FAT32_Test_Fat_Entry_Validity___EXIT
                  LDA #-4 ; empty sector
                  BRL FAT32_Test_Fat_Entry_Validity_ERROR_EXIT
                  FAT32_Test_Fat_Entry_Validity___EXIT:
                  LDA #1
                  FAT32_Test_Fat_Entry_Validity_ERROR_EXIT:
                  ;PLA
 .comment
 PHX
 PHA
 BRA _TEST_TEXT_8
 _text_8 .text "---- Entry validity ",0
 _TEST_TEXT_8:
 LDX #<>_text_8
 LDA #`_text_8
 JSL IPUTS_ABS
 LDA FAT32_FAT_Entry +2 ; test for EOC (End Of Cluster)
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA FAT32_FAT_Entry ; test for EOC (End Of Cluster)
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA #$00
 JSL IPUTC
 PLA
 PHA
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA #$0D
 JSL IPUTC
 PLA
 PLX
 .endc
                  RTL

;-------------------------------------------------------------------------------
; In
; FAT32_FAT_Entry : index where to start looking for a free fat entry
; Out
; A : 1 find an empty sector
; FAT32_FAT_Next_Entry => fat entry where the free cluster is
;-------------------------------------------------------------------------------
FAT32_FIND_FREE_FAT_ENTRY
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  LDA FAT32_FAT_Next_Entry
                  CMP #0
                  BNE FAT32_FIND_FREE_FAT_ENTRY__FAT_ENTRY_NOT_NULL
                  LDA FAT32_FAT_Next_Entry +2
                  AND #$0FFF
                  CMP #0
                  BNE FAT32_FIND_FREE_FAT_ENTRY__FAT_ENTRY_NOT_NULL
                  LDA #1
                  BRA  FAT32_FIND_FREE_FAT_ENTRY__FOUND
 FAT32_FIND_FREE_FAT_ENTRY__FAT_ENTRY_NOT_NULL:
                  ; increment the Fat entry index by 1
                  LDA FAT32_FAT_Entry
                  STA ADDER_A
                  LDA FAT32_FAT_Entry +2
                  STA ADDER_A +2
                  LDA #1 ; load -1 in comp 2
                  STA ADDER_B
                  LDA #$0
                  STA ADDER_B +2
                  LDA ADDER_R
                  STA FAT32_FAT_Entry
                  LDA ADDER_R +2
                  STA FAT32_FAT_Entry +2
                  ; Test if the index is not too big
                  CMP #$0FFF
                  BNE FAT32_FIND_FREE_FAT_ENTRY
                  LDA FAT32_FAT_Entry
                  CMP #$FFEF ; last usable cluster is 0x0FFFFFEF
                  BNE FAT32_FIND_FREE_FAT_ENTRY
                  LDA #0
 FAT32_FIND_FREE_FAT_ENTRY__FOUND:
                  RTL

;-------------------------------------------------------------------------------
;- Copy the data from the FAT32 buffer at address FAT32_Data_Destination_buffer
;-------------------------------------------------------------------------------
FAT32_Data_Destination_buffer .dword 0

FAT32_Copy_Cluster_at_Address
                  PHX
                  PHY
                  PHA
                  LDX #<>FAT32_DATA_ADDRESS_BUFFER_512
                  LDA @l FAT32_Data_Destination_buffer
                  TAY
                  LDA FAT32_Data_Destination_buffer+2
                  setas
                  ;STA FAT32_Copy_Cluster_at_Address_MVN + 2 ; rewrite the second parameter of the instruction in RAM
                  setal
                  LDA #$0200 ; 512 Byte


 ;FAT32_Copy_Cluster_at_Address_MVN: MVN `FAT32_DATA_ADDRESS_BUFFER_512,$B0
 ;FAT32_Copy_Cluster_at_Address_MVN: MVN `FAT32_DATA_ADDRESS_BUFFER_512,`FAT32_Data_Destination_buffer
                  ; inc the buffer adres by 512
                  setas
                  LDA @lFAT32_Data_Destination_buffer+2
                  STA @l FAT32_Copy_Cluster_at_Address_MVN+ 3
                  ;JSL IPRINT_HEX ; print the sector
                  LDA @lFAT32_Data_Destination_buffer+1
                  STA @l FAT32_Copy_Cluster_at_Address_MVN+ 2
                  ;JSL IPRINT_HEX ; print the sector
                  LDA @lFAT32_Data_Destination_buffer+0
                  STA @l FAT32_Copy_Cluster_at_Address_MVN+ 1
                  ;JSL IPRINT_HEX ; print the sector
                  setal
 .comment
 PHX
 PHA
 PHY
 BRA _TEST_TEXT_228
 _text_228 .text "---- cpy cluster address editing ",0
 _TEST_TEXT_228:
 LDX #<>_text_228
 LDA #`_text_228
 JSL IPUTS_ABS
 LDA #$00
 JSL IPUTC
 LDA FAT32_Data_Destination_buffer +2 ; test for EOC (End Of Cluster) MSB 24
 JSL IPRINT_HEX
 LDA FAT32_Data_Destination_buffer +1 ; test for EOC (End Of Cluster)
 JSL IPRINT_HEX
 LDA FAT32_Data_Destination_buffer +0 ; test for EOC (End Of Cluster) LSB 24
 JSL IPRINT_HEX
 LDA #$00
 JSL IPUTC
 LDA FAT32_Copy_Cluster_at_Address_MVN ; test for EOC (End Of Cluster)
 JSL IPRINT_HEX
 LDA #$00
 JSL IPUTC
 LDA FAT32_Copy_Cluster_at_Address_MVN +3 ; test for EOC (End Of Cluster)
 JSL IPRINT_HEX
 LDA FAT32_Copy_Cluster_at_Address_MVN +2 ; test for EOC (End Of Cluster)
 JSL IPRINT_HEX
 LDA FAT32_Copy_Cluster_at_Address_MVN +1 ; test for EOC (End Of Cluster)
 JSL IPRINT_HEX
 LDA #$00
 JSL IPUTC
 LDA FAT32_Data_Destination_buffer+2 ; test for EOC (End Of Cluster)
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA FAT32_Data_Destination_buffer ; test for EOC (End Of Cluster)
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA #$0D
 JSL IPUTC
 PLY
 PLA
 PLX
 .endc
                  LDX #0
 FAT32_Copy_Cluster_at_Address__READ_LOOP_BYTE:
                  LDA @l FAT32_DATA_ADDRESS_BUFFER_512,x
  FAT32_Copy_Cluster_at_Address_MVN STA @l FAT32_Data_Destination_buffer,x
                  ;JSL IPRINT_HEX
                  ;JSL IPUTC
                  INX
                  INX
                  CPX #$200
                  BNE FAT32_Copy_Cluster_at_Address__READ_LOOP_BYTE

                  LDA #$0200
                  CLC
                  ADC FAT32_Data_Destination_buffer
                  STA FAT32_Data_Destination_buffer
                  BCC FAT32_Copy_Cluster_at_Address__No_over_flow_adresse
                  LDA #$0001
                  CLC
                  ADC FAT32_Data_Destination_buffer+2
                  STA FAT32_Data_Destination_buffer+2
 FAT32_Copy_Cluster_at_Address__No_over_flow_adresse
 .comment
 PHX
 PHA
 BRA _TEST_TEXT_229
 _text_229 .text "---- cpy cluster inc address ",0
 _TEST_TEXT_229:
 LDX #<>_text_229
 LDA #`_text_229
 JSL IPUTS_ABS
 LDA FAT32_Data_Destination_buffer+2 ; test for EOC (End Of Cluster)
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA FAT32_Data_Destination_buffer ; test for EOC (End Of Cluster)
 XBA
 JSL IPRINT_HEX
 XBA
 JSL IPRINT_HEX
 LDA #$0D
 JSL IPUTC
 PLA
 PLX
 .endc
                  setaxl
                  PLA
                  PLY
                  PLX
                  RTL
