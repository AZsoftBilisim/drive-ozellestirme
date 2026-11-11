#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	UseStoreFormats = GetFunctionalOption("UseStoreFormats");
	
	For Each RsRecord In ThisObject Do
		
		If Not ValueIsFilled(RsRecord.Author) Then
			RsRecord.Author = UsersClientServer.CurrentUser();
		EndIf;
		
		RsRecord.RecordDate = CurrentSessionDate();
		
		If UseStoreFormats And RsRecord.ControlProductRange And Not ValueIsFilled(RsRecord.StoreFormat) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Khuôn dạng cửa hàng"".';
							|ru = 'Поле ""Формат магазина"" не заполнено.';
							|en = '""Store format"" is not filled in.'; fa = '""Store format"" is not filled in.';
							|it = 'Il campo ""Formato di negozio"" non è stato compilato.';
							|pl = 'Pole ""Format sklepu"" nie jest wypełnione.';
							|tr = '""Mağaza Formatı"" alanı doldurulmadı.'");
			CommonClientServer.MessageToUser(ErrorText,
				, 
				"StoreFormat",
				CommonClientServer.PathToTabularSection("ThisObject",RsRecord.LineNumber,"StoreFormat"),
				Cancel);
		
		EndIf; 
	
	EndDo; 
	
EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	For Each RsRecord In ThisObject Do
		
		WarehouseStore = Common.ObjectAttributeValue(RsRecord.Warehouse, "WarehouseStore");
		ThisIsRetailWarehouse = (WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
		
		If RsRecord.ControlProductRange And Not ThisIsRetailWarehouse Then
			
			RsRecord.ControlProductRange = False;
			
		EndIf; 
		
		RecordSet = InformationRegisters.HistoryOfStoreFormatChange.CreateRecordSet();
		RecordSet.Filter.Warehouse.Set(RsRecord.Warehouse);
		RecordSet.Filter.Period.Set(RsRecord.Period);
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf