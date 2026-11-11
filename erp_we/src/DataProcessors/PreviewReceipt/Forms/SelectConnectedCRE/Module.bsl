
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	EquipmentTable = Parameters.EquipmentTable;
	
	For Each HardwareTableRow In EquipmentTable Do
		ListLine = List.Add();
		ListLine.Equipment = HardwareTableRow.Equipment;
		ListLine.FDFVersion = HardwareTableRow.FDFVersion;
		ListLine.Attached = HardwareTableRow.Attached;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Select(Command)
	
	ProcessCCTSelection();
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessCCTSelection();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function RepresentationOfTheKKT(CREEquipment)
	
	Return ("" +  Common.ObjectAttributeValue(CREEquipment, "Description"));
	
EndFunction

&AtClient
Procedure ProcessCCTSelection()
	
	ClearMessages();
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn MTT';
										|ru = 'ККТ не выбран';
										|en = 'Cash register is not selected'; fa = 'Cash register is not selected';
										|it = 'Registratore di cassa non scelto';
										|pl = 'Kasa nie jest wybrana';
										|tr = 'Yazar kasa ekipmanları seçilmedi'"));
		
		Return;
	EndIf;
	
	If Not CurrentRow.Attached Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa kết nối MTT ""%1""';
				|ru = 'ККТ ""%1"" не подключен';
				|en = 'Cash register ""%1"" is not connected'; fa = 'Cash register ""%1"" is not connected';
				|it = 'Registratore di cassa ""%1"" non collegato';
				|pl = 'Kasa ""%1"" nie jest podłączona';
				|tr = 'Yazar kasa ekipmanları ""%1"" bağlı değil'"),
			RepresentationOfTheKKT(CurrentRow.Equipment));
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	StructureSelectedCKTEquipment = New Structure();
	StructureSelectedCKTEquipment.Insert("Equipment", CurrentRow.Equipment);
	StructureSelectedCKTEquipment.Insert("FDFVersion", CurrentRow.FDFVersion);
	
	Close(StructureSelectedCKTEquipment);
	
EndProcedure

#EndRegion