#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	If Not IsFolder Then
		
		If StorageBinType <> Enums.TypesOfStorageCells.Location
				And StorageBinType <> Enums.TypesOfStorageCells.Archive
			Or WarehousesServer.UseBinLocationWarehousingForInformation(Owner, Premise)
				And Not WarehousesServer.UseBinLocationWarehousing(Owner, Premise,,False) Then
			
			StorageArea 	= Catalogs.StorageAreas.EmptyRef();
			AvailabilityLevel 	= 0;
			StandardSize  		= Catalogs.StandardSizesOfStorageBins.EmptyRef();
			MaximumFillingRateByWeight 		= 0;
			MaximumFillingRateByVolume    = 0;
			
			If WarehousesServer.UseBinLocationWarehousingForInformation(Owner, Premise)
					And Not WarehousesServer.UseBinLocationWarehousing(Owner, Premise,,False) Then
				StorageBinType  = Enums.TypesOfStorageCells.EmptyRef();
			Else
				WarehouseZone  	                         = Catalogs.WarehouseZones.EmptyRef();
				StorageArea                              = Catalogs.StorageAreas.EmptyRef();
				TabIndex 		                         = 0;
				AvailabilityLevel                           = 0;
				MaximumFillingRateByWeight   = 0;
				MaximumFillingRateByVolume = 0;
			EndIf;
			
		Else
			If AvailabilityLevel = 0 Then
			
				AvailabilityLevel = 1;
				
			EndIf;
			
			If MaximumFillingRateByWeight = 0 Then
				
				MaximumFillingRateByWeight = 100;
				
			EndIf;
			
			If MaximumFillingRateByVolume = 0 Then
				
				MaximumFillingRateByVolume = 100;
				
			EndIf;
			
		EndIf;	
		
	EndIf;
	
EndProcedure // Before recording()

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	ParametersStructure = New Structure("Warehouse,Premise",Owner, Premise);
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseBinLocationWarehousing(Owner, Premise,,False) Then
		
		If Not IsFolder Then
			NotCheckedAttributeArray.Add("StorageBinType");
		EndIf;
		
		If Not WarehousesServer.UseBinLocationWarehousingForInformation(Owner, Premise) Then
			
			MessageText = NStr("vi = 'Theo kho ""%Warehouse%"" không sử dụng cơ chế cất giữ hàng hóa theo địa chỉ!';
								|ru = 'По складу ""%Warehouse%"" не используется адресное хранение!';
								|en = 'Bin location system is not used for warehouse ""%Warehouse%"".'; fa = 'Bin location system is not used for warehouse ""%Warehouse%"".';
								|it = 'Nel magazzino ""%Warehouse%"" non viene utilizzata un''archiviazione indirizzata!';
								|pl = 'Dla magazynu ""%Warehouse%"" nie jest używane przechowywanie adresowe!';
								|tr = '""%Warehouse%"" ambarında depo konum takibi kullanılmıyor!'");
			MessageText = StrReplace(MessageText,"%Warehouse%",WarehousesServer.GetWarehousePresentation(Owner,Premise));
			
			CommonClientServer.MessageToUser(MessageText,ThisObject,"Warehouse","Object",Cancel);
		EndIf;
	EndIf;
	
	If Not WarehousesServer.UseWarerooms(Owner) Then
		
		NotCheckedAttributeArray.Add("Premise");
		
	ElsIf ValueIsFilled(Parent) Then
		
		ParentAttributes = Common.ObjectAttributesValues(Parent,New Structure("Premise"));
		
		If ParentAttributes.Premise <> Premise Then
			MessageText = NStr("vi = 'Trong nhóm ""%Group%"" tất cả các ô hàng cần phải theo nhà kho ""%Premise%""';
								|ru = 'В группе ""%Group%"" все ячейки должны быть по помещению ""%Premise%""';
								|en = 'All bins should be by wareroom ""%Premise%"" in group ""%Group%""'; fa = 'All bins should be by wareroom ""%Premise%"" in group ""%Group%""';
								|it = 'Nel gruppo ""%Group%"" tutte le celle devono essere della stanza ""%Premise%""';
								|pl = 'W grupie ""%Group%"" wszystkie komórki muszą być wg pomieszczenia ""%Premise%""';
								|tr = '""%Group%"" grubunda tüm hücreler alana göre doldurulmalı ""%Premise%""'");
			MessageText = StrReplace(MessageText,"%Premise%",ParentAttributes.Premise);
			MessageText = StrReplace(MessageText,"%Group%",Parent);
			
			CommonClientServer.MessageToUser(MessageText,ThisObject,"Premise","Object",Cancel);
		EndIf;
	EndIf;
	
	If UseFrequencyOfBinInventoryRecounts 
		<> Enums.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.UseCellSettings Then
		
		NotCheckedAttributeArray.Add("NumberOfDaysOfPhysicalCountCycle");
			
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf
#EndIf