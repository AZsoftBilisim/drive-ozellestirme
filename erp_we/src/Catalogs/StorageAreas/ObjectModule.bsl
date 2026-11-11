#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not SeparateStorageArea Then
		ControlQuantityOfAssignmentsInBins = False;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseWarerooms(Owner) Then
    	NotCheckedAttributeArray.Add("Premise");
	EndIf;
				
	If Not WarehousesServer.UseBinLocationWarehousing(Owner, Premise) Then
		
		MessageText = NStr("vi = 'Theo kho ""%Warehouse%"" không sử dụng cơ chế lưu hàng hóa hai pha!';
							|ru = 'По складу ""%Warehouse%"" не используется адресное хранение!';
							|en = 'Bin location system is not used for warehouse ""%Warehouse%"".'; fa = 'Bin location system is not used for warehouse ""%Warehouse%"".';
							|it = 'Nel magazzino ""%Warehouse%"" non viene utilizzata un''archiviazione indirizzata!';
							|pl = 'Dla magazynu ""%Warehouse%"" nie jest używane przechowywanie adresowe!';
							|tr = '""%Warehouse%"" ambarında depo konum takibi kullanılmıyor!'");
		MessageText = StrReplace(MessageText,"%Warehouse%",WarehousesServer.GetWarehousePresentation(Owner,Premise));
		
		CommonClientServer.MessageToUser(MessageText,ThisObject,"Warehouse","Object",Cancel);
	EndIf;
	
	If FrequencyOfBinInventoryRecount 
		= Enums.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.DontUse Then
		
		NotCheckedAttributeArray.Add("NumberOfDaysOfPhysicalCountCycle");
			
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf