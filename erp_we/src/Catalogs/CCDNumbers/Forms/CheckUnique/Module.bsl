
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TableFound.Load(GetFromTempStorage(Parameters.AddressTemporaryStorageTableFound));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAnExisting(Command)
	
	ClearMessages();
	
	CurrentRow = Items.TableFound.CurrentData;
	
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Chưa chọn số đăng ký lô hàng của bộ đóng gói';
							|ru = 'Номер РНПТ комплекта не выбрана';
							|en = 'RNPT of the kit is not selected'; fa = 'RNPT of the kit is not selected';
							|it = 'Numero di registrazione lotti prodotti del set non selezionato';
							|pl = 'Numer rejestracyjny partii towaru zestawu nie jest wybrany';
							|tr = 'Setin RNPT numarası seçilmedi'");
		
		CommonClient.MessageToUser(MessageText, , "TableFound");
		
		Return;
	EndIf;
	
	ProcessingResult = ProductsClient.NewCompletionProcessingResult();
	ProcessingResult.Action	= "SelectAnExisting";
	ProcessingResult.Ref	= CurrentRow.Ref;
	
	Close(ProcessingResult);
	
EndProcedure

&AtClient
Procedure ContinuePopulation(Command)
	
	ProcessingResult = ProductsClient.NewCompletionProcessingResult();
	ProcessingResult.Action = "ContinuePopulation";
	
	Close(ProcessingResult);
	
EndProcedure

#EndRegion