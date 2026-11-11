
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	List.Load(GetFromTempStorage(Parameters.TableAddress));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ListSelectionClient();
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsSelectedSenders

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ListSelectionClient();
	
EndProcedure
#EndRegion

#Region Private

&AtClient
Procedure ListSelectionClient()
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Chọn một dòng.';
							|ru = 'Выберите строку.';
							|en = 'Select a line.'; fa = 'Select a line.';
							|it = 'Selezionare una riga.';
							|pl = 'Wybierz wiersz.';
							|tr = 'Satırı seç.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	Result = New Structure;
	
	Result.Insert("Sender", CurrentData.Sender); 
	Result.Insert("Contract", CurrentData.Contract); 
	Result.Insert("PricesKind", CurrentData.PricesKind); 
	Result.Insert("InventoryType", CurrentData.InventoryType);
	Result.Insert("BusinessOperation", CurrentData.BusinessOperation);
	
	Close(Result);

EndProcedure

#EndRegion
