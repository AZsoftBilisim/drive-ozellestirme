#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.Separator.ReadOnly = Not AccessRight("Update", Metadata.Catalogs.StorageBins);
	Separator = "-";
	
	CodeFillSelectionList(Items.Code, Object, Separator);
	NameFillSelectionList(Items.Description, Object.Code);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StorageBinTypeOnChange(Item)
	
	ArrayOfCellTypes = New Array;
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesAcceptance());
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesShipment());
	
	If ArrayOfCellTypes.Find(Object.StorageBinType) <> Undefined
		And Object.UseFrequencyOfBinInventoryRecounts 
			= PredefinedValue("Enum.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.UseStorageAreaSettings") Then
		Object.UseFrequencyOfBinInventoryRecounts 
			= PredefinedValue("Enum.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.DontUse");
	EndIf;
	
	SetVisibilityByStorageCellType();
	
EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	If IsBlankString(Object.Description) Then
		Object.Description = TrimAll(Object.Code);
	EndIf;
	
	NameFillSelectionList(Items.Description, Object.Code);
	
EndProcedure

&AtClient
Procedure GroupElementAddressingDetailsWhenChanged(Item)
	
	CodeFillSelectionList(Items.Code, Object, Separator);
	
EndProcedure

&AtClient
Procedure StandardSizeOnChange(Item)
	
	ConfigureAvailabilityOfFullnessFactors();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.StorageBins.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

Procedure OnReadCreateAtServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Object.Owner,Object.Premise));
		
	FormControl();
	
EndProcedure

#Region Other

&AtServer
Procedure SetVisibilityByStorageCellType()
	
	Items.GroupContent.Visible = UseBinLocationWarehousing And ((Object.StorageBinType = Enums.TypesOfStorageCells.Location)
										  Or  (Object.StorageBinType = Enums.TypesOfStorageCells.Archive));
	Items.AvailabilityLevel.Visible = (Object.StorageBinType = Enums.TypesOfStorageCells.Location)
										  Or  (Object.StorageBinType = Enums.TypesOfStorageCells.Archive);
	Items.StorageArea.Visible = (Object.StorageBinType = Enums.TypesOfStorageCells.Location)
										  Or  (Object.StorageBinType = Enums.TypesOfStorageCells.Archive);
	
	Items.TabIndex.Visible = (Object.StorageBinType = Enums.TypesOfStorageCells.Location)
										Or  (Object.StorageBinType = Enums.TypesOfStorageCells.Archive)
										Or Not ValueIsFilled(Object.StorageBinType);
										
	Items.WarehouseZone.Visible = (Object.StorageBinType = Enums.TypesOfStorageCells.Location)
										Or  (Object.StorageBinType = Enums.TypesOfStorageCells.Archive)
										Or Not ValueIsFilled(Object.StorageBinType);
																			
										
	Items.GroupInventoryFrequencyCellsStorageAreaSettings.Visible = 
	    UseBinLocationWarehousing
		And (Object.StorageBinType = Enums.TypesOfStorageCells.Archive 
			Or Object.StorageBinType = Enums.TypesOfStorageCells.Location);									
						
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfFullnessFactors()
	
	If Not ValueIsFilled(Object.StandardSize) Then
		Return;
	EndIf;
	
	StandardSizeDetails = Common.ObjectAttributesValues(Object.StandardSize,
		"NotLimitedByDimensions, NotLimitedByCarryingCapacity");
	
	Items.GroupFillingByVolume.Enabled = Not StandardSizeDetails.NotLimitedByDimensions;
	Items.GroupFillingByWeight.Enabled = Not StandardSizeDetails.NotLimitedByCarryingCapacity;
	
EndProcedure

&AtServer
Procedure FormControl()
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Owner, Object.Premise);
	
	SetVisibilityByStorageCellType();
	ConfigureAvailabilityOfFullnessFactors();
	
	TMCommonUseClientServer.SetFormItemProperty(
			Items, 
			"GroupPlacementSelection", 
			"ShowTitle",
			UseBinLocationWarehousing);		
			
	Items.GroupCellInventoryPeriod.Visible = UseBinLocationWarehousing;
	
	If UseBinLocationWarehousing 
		And (Object.StorageBinType = Enums.TypesOfStorageCells.Archive
			Or Object.StorageBinType = Enums.TypesOfStorageCells.Location) Then 
		FillInStorageAreaInventoryFrequencySettings();	
	EndIf;
			
	UsingPeriodicityOfCellInventoryWhenChangingOnServer_();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CodeFillSelectionList(Item, Object, Separator)
	
	If Separator = "P" Then
		DelimiterString = " ";	
	ElsIf Separator = "N"	Then
		DelimiterString = "";	
	Else
		DelimiterString = Separator;
	EndIf;
	
	Address = TrimAll(Object.Section3)
			+ ?(IsBlankString(Object.Section3), "", DelimiterString)
			+ TrimAll(Object.Line)
			+ ?(IsBlankString(Object.Line), "", DelimiterString)
			+ TrimAll(Object.Rack)
			+ ?(IsBlankString(Object.Rack), "", DelimiterString)
			+ TrimAll(Object.Tier) 
			+ ?(IsBlankString(Object.Tier), "", DelimiterString)
			+ TrimAll(Object.Position);
			
	If Right(Address, 1) = DelimiterString Then
		Address = Left(Address, StrLen(Address)-1);
	EndIf;
	
	Item.ChoiceList.Clear();
	Item.ChoiceList.Add(Address);
	
EndProcedure

&AtClientAtServerNoContext
Procedure NameFillSelectionList(Item, Code)
	
	Item.ChoiceList.Clear();
	Item.ChoiceList.Add(TrimAll(Code));
	
EndProcedure

#EndRegion


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure UsingThePeriodicityOfTheCellInventoryWhenChanging(Item)
	UsingPeriodicityOfCellInventoryWhenChangingOnServer_();
EndProcedure

&AtClient
Procedure StorageAreaOnChange(Item)
	FillInStorageAreaInventoryFrequencySettings();	
EndProcedure

&AtServer
Procedure UsingPeriodicityOfCellInventoryWhenChangingOnServer_()
	
	If Not UseBinLocationWarehousing Then 
		Return
	EndIf;
	
	If Object.UseFrequencyOfBinInventoryRecounts 
			= Enums.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.UseCellSettings Then 
		Items.NumberOfDaysBetweenStocktakingsPages.CurrentPage = Items.NumberOfDaysBetweenStocktakingsAvailable;
	Else
		Object.NumberOfDaysOfPhysicalCountCycle = 0;
		Items.NumberOfDaysBetweenStocktakingsPages.CurrentPage = Items.TheNumberOfDaysBetweenInventoriesIsNotAvailable;
	EndIf;
				
EndProcedure

&AtServer
Procedure FillInStorageAreaInventoryFrequencySettings()
	If ValueIsFilled(Object.StorageArea) Then
		NumberOfDaysOfPhysicalCountCycle = Common.ObjectAttributeValue(
				Object.StorageArea, 
				"NumberOfDaysOfPhysicalCountCycle");
		If NumberOfDaysOfPhysicalCountCycle = 0 Then 
			SettingsOfFrequencyUseForStorageAreaRecount
					= NStr("vi = 'không sử dụng kiểm kê định kỳ trong vùng cất giữ.';
							|ru = 'периодическая инвентаризация в области хранения не используется.';
							|en = 'periodic inventory count is not used in the storage area.'; fa = 'periodic inventory count is not used in the storage area.';
							|it = 'l''inventario periodico nell''area di stoccaggio non viene utilizzato.';
							|pl = 'okresowa inwentaryzacja w obszarze przechowywania nie jest wykorzystywana.';
							|tr = 'depolama alanında periyodik fiziksel stok sayımı kullanılmıyor.'");
		Else
			SettingsOfFrequencyUseForStorageAreaRecount = NStr("vi = 'kiểm đếm %each% %DaysCount%.';
																|ru = 'пересчитывать %each% %DaysCount%.';
																|en = 'recalculate %each% %DaysCount%.'; fa = 'recalculate %each% %DaysCount%.';
																|it = 'rifare il conto %each% %DaysCount%.';
																|pl = 'przeliczaj %each% %DaysCount%';
																|tr = 'yeniden hesapla %each%%DaysCount%.'");
			SettingsOfFrequencyUseForStorageAreaRecount = StrReplace(
					SettingsOfFrequencyUseForStorageAreaRecount,
					"%each%",
					?(NumberOfDaysOfPhysicalCountCycle = 1, NStr("vi = 'mỗi';
																|ru = 'каждый';
																|en = 'each'; fa = 'each';
																|it = 'ogni';
																|pl = 'każdy';
																|tr = 'her'"), NStr("vi = 'mỗi';
																						|ru = 'каждый';
																						|en = 'each'; fa = 'each';
																						|it = 'ogni';
																						|pl = 'każdy';
																						|tr = 'her'")));
			DaysCount = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(
					NumberOfDaysOfPhysicalCountCycle, 
					 NStr("vi = 'ngày';
							|ru = 'день,дня,дней';
							|en = 'day,day,days'; fa = 'day,day,days';
							|it = 'giorno, giorni, giorni';
							|pl = 'dzień,dni,dni';
							|tr = 'gün,gün,günler'"));
			SettingsOfFrequencyUseForStorageAreaRecount = StrReplace(
					SettingsOfFrequencyUseForStorageAreaRecount,
					"%DaysCount%",
					DaysCount);
		EndIf;
	Else
		SettingsOfFrequencyUseForStorageAreaRecount = NStr("vi = '<chưa chỉ ra khu vực cất giữ, chưa tiến hành kiểm kê định kỳ>';
															|ru = '<область хранения не указана, периодическая инвентаризация не проводится>';
															|en = '<storage area is not specified, periodic inventory count is not performed>'; fa = '<storage area is not specified, periodic inventory count is not performed>';
															|it = '<storage area is not specified, periodic inventory count is not performed>';
															|pl = '<obszar przechowywania nie został określony, okresowa inwentaryzacja nie jest przeprowadzana>';
															|tr = '<depolama alanı belirtilmemiş, periyodik fiziksel stok sayımı yapılmıyor>'");
	EndIf;
EndProcedure

#EndRegion
