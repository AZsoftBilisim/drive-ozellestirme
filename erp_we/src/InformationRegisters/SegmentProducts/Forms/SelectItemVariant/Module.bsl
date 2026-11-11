
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not Parameters.Property("CharacteristicTable") Then
		Cancel = True;
		Return;
	EndIf;
	
	If Parameters.ReadOnly = True Then
		
		Items.Characteristics.ReadOnly              = True;
		Items.CharacteristicsCheckAll.Enabled = False;
		Items.CharacteristicsUncheckAll.Enabled      = False;
		
		Title = NStr("vi = 'Đặc tính đưa vào phân nhóm';
					|ru = 'Характеристики входящие в сегмент';
					|en = 'Variants included in segment'; fa = 'Variants included in segment';
					|it = 'Caratteristiche incluse nel segmento';
					|pl = 'Charakterystyki zawarte w segmencie';
					|tr = 'Segmente dahil olan varyantlar'");
		Items.Select.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Close';
									|tr = 'Kapat'");
		
	Else
		
		OpenedForSelection = True;
		
	EndIf;
	
	CommonClientServer.SupplementTable( Parameters.CharacteristicTable, Characteristics);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If OpenedForSelection Then
		
		Close(Characteristics);
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SelectOrClearAll(True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SelectOrClearAll(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectOrClearAll(Set)

	For Each TableRow In Characteristics Do
	
		TableRow.BelongsToSegment = Set;
	
	EndDo;

EndProcedure // Install the New Tabs()

#EndRegion
