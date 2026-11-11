
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	Record.Period = CurrentSessionDate();
	
	If Record.ControlProductRange Then
	
		Items.StoreFormat.AutoMarkIncomplete = True;
		Items.StoreFormat.AutoChoiceIncomplete = True;
	
	Else
	
		Items.StoreFormat.AutoMarkIncomplete = False;
		Items.StoreFormat.AutoChoiceIncomplete = False;
	
	EndIf;
	
	WarehouseStore = Common.ObjectAttributeValue(Record.Warehouse, "WarehouseStore");
	ThisIsRetailWarehouse = (WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	
	If Record.RetailPricesFromStoreFormat Then
		RetailPricesFromTheStoreFormat = "StoreFormat";
	Else
		RetailPricesFromTheStoreFormat = "Warehouse";
	EndIf;
	
	Items.ControlProductRange.Enabled = ThisIsRetailWarehouse;

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	ChangeRetailPriceStorageLocationSettings();
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	WarehouseStore = Common.ObjectAttributeValue(Record.Warehouse, "WarehouseStore");
	ThisIsRetailWarehouse = (WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	If Record.RetailPricesFromStoreFormat Then
		RetailPricesFromTheStoreFormat = "StoreFormat";
	Else
		RetailPricesFromTheStoreFormat = "Warehouse";
	EndIf;
	
	Items.ControlProductRange.Enabled = ThisIsRetailWarehouse;

	ChangeRetailPriceStorageLocationSettings();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ControlProductRangeOnChange(Item)
	
	If Record.ControlProductRange Then
	
		Items.StoreFormat.AutoMarkIncomplete = True;
		Items.StoreFormat.AutoChoiceIncomplete = True;
	
	Else
	
		Items.StoreFormat.AutoMarkIncomplete = False;
		Items.StoreFormat.AutoChoiceIncomplete = False;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseWhenChangedOnServer();
EndProcedure

&AtClient
Procedure StoreFormatOnChange(Item)
	StoreFormatWhenChangedOnServer();
EndProcedure

&AtClient
Procedure StoreFormatClearing(Item, StandardProcessing)
	StoreFormatCleaningOnServer();
EndProcedure

&AtClient
Procedure RetailPricesFromTheStoreFormatOnChange(Item)
	
	Record.RetailPricesFromStoreFormat = (RetailPricesFromTheStoreFormat = "StoreFormat");
	
	UpdatePriceViewPresentations();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	WarehouseStore = Common.ObjectAttributeValue(Record.Warehouse, "WarehouseStore");
	ThisIsRetailWarehouse = (WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	
	Items.ControlProductRange.Enabled = ThisIsRetailWarehouse;

	If Record.ControlProductRange And Not ThisIsRetailWarehouse Then
	
		Record.ControlProductRange = False;
	
	EndIf; 
	
	UpdatePriceViewPresentations();
	
EndProcedure

&AtServer
Procedure StoreFormatWhenChangedOnServer()
	
	ChangeRetailPriceStorageLocationSettings();	

EndProcedure

&AtServer
Procedure StoreFormatCleaningOnServer()
	
	ChangeRetailPriceStorageLocationSettings();
		
EndProcedure

&AtServer
Procedure ChangeRetailPriceStorageLocationSettings()
	
	If Not UsePriceManagementSystem25 Then
		
		Items.GroupRetailPrices.Visible = False;
		Return;
		
	EndIf;

	Items.GroupRetailPrices.Visible = True;
	
	StoreFormatFilledIn = ValueIsFilled(Record.StoreFormat);
	
	Items.GroupRetailPrices.Enabled = StoreFormatFilledIn;
	
	If Not StoreFormatFilledIn Then

		Record.RetailPricesFromStoreFormat = False;
		RetailPricesFromTheStoreFormat = "Warehouse";
		
	EndIf;
	
	UpdatePriceViewPresentations();
	
EndProcedure

&AtServer
Procedure UpdatePriceViewPresentations()
	If Record.RetailPricesFromStoreFormat Then
		RetailPriceStorageFacility = Record.StoreFormat;
	Else	
		RetailPriceStorageFacility = Record.Warehouse;
	EndIf;
	
	TypesOfPrices = Common.ObjectAttributesValues(RetailPriceStorageFacility, "RetailPriceType, SpecialPriceType");
	
	If ValueIsFilled(TypesOfPrices.RetailPriceType) Then
		RetailPriceViewView = TypesOfPrices.RetailPriceType;
	Else	 
		RetailPriceViewView = "<not specified>";
	EndIf;
	
	If ValueIsFilled(TypesOfPrices.SpecialPriceType) Then
		IndividualTypeOfPricesPresentation = "<used>";
	Else	 
		IndividualTypeOfPricesPresentation = "<not used>";
	EndIf;
	
EndProcedure

#EndRegion

