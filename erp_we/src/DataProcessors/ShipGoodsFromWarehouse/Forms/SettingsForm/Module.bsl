#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Premise = Parameters.Premise;
	Warehouse = Parameters.Warehouse;
	
	WarehouseIDOfPremises = String(Warehouse.UUID()) +  String(Premise.UUID()) + String(Premise.UUID());
	
	CustomizeGenerationByWarerooms = 0;
	ByOneWareroom = False;
	
	Settings = Common.CommonSettingsStorageLoad("ShipmentManagementFormSettingsFormFormSettings" + WarehouseIDOfPremises, "");
	If Settings <> Undefined Then
		If Settings.Property("ShippingZone") Then	
			ShippingZone = Settings.ShippingZone;		
		EndIf;
		If Settings.Property("AssignShippingArea") Then	
			AssignShippingArea = Settings.AssignShippingArea;		
		EndIf;
		If Settings.Property("ByAllReferences") Then	
			ByAllReferences = Settings.ByAllReferences;		
		EndIf;
		If Settings.Property("ByOneWareroom") Then	
			ByOneWareroom = Settings.ByOneWareroom;		
		EndIf;
		If Settings.Property("CustomizeGenerationByWarerooms") Then	
			CustomizeGenerationByWarerooms = Settings.CustomizeGenerationByWarerooms;		
		EndIf;
	EndIf;
		
	Parameters.Property("UseWarerooms", UseWarerooms);
	
	SetVisibility1();
	SetDefaults();
	SetAvailability();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssignAShippingZoneWhenChanging(Item)
	Items.ShippingZone.Enabled           = AssignShippingArea;
EndProcedure

&AtClient
Procedure CustomizeGenerationByWareroomsOnChange(Item)
	If CustomizeGenerationByWarerooms = "0" Then
		ByOneWareroom = False;
	Else	
		ByOneWareroom = True;		
	EndIf;			
	
	SetDefaults();
	SetAvailability()

EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	PlacementWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseWithoutSaving(Command)
	Close(DialogReturnCode.Cancel);
EndProcedure

&AtClient
Procedure CloseWithSaving(Command)
	
	ClearMessages();
	CheckError = False;

	If Items.AssignAShippingZone.Visible
		And AssignShippingArea
		And Not ValueIsFilled(ShippingZone) Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Khu vực giao hàng"".';
							|ru = 'Поле ""Зона отгрузки"" не заполнено.';
							|en = '""Outbound area"" is not filled in.'; fa = '""Outbound area"" is not filled in.';
							|it = 'Il campo ""Area della spedizione"" non è compilato.';
							|pl = 'Nie wypełniono pola ""Зона отгрузки"".';
							|tr = '""Yükleme alanı"" alanı doldurulmadı.'");
		
		CommonClientServer.MessageToUser(MessageText,,"ShippingZone",);
		
		CheckError = True;
		
	EndIf;
	
	If UseWarerooms
		And ByOneWareroom
		And Not ValueIsFilled(Premise)Then
		MessageText = NStr("vi = 'Trường ""Địa điểm"" chưa điền.';
							|ru = 'Поле ""Помещение"" не заполнено.';
							|en = '""Wareroom"" is not filled in.'; fa = '""Wareroom"" is not filled in.';
							|it = 'Il campo ""Collocamento"" non è compilato.';
							|pl = 'Nie wypełniono pola ""Помещение"".';
							|tr = '""Alan"" alanı doldurulmadı.'");
		
		CommonClientServer.MessageToUser(MessageText,,"ShippingZone",);
		
		CheckError = True;		
	EndIf;
	
	If CheckError Then
		Return;
	EndIf;
	
	WarehouseIDOfPremises = String(Warehouse.UUID()) + String(Premise.UUID()) + String(Premise.UUID());

	ClosingParameters = New Structure;
	ClosingParameters.Insert("ShippingZone",ShippingZone);
	ClosingParameters.Insert("AssignShippingArea", AssignShippingArea);   
	ClosingParameters.Insert("ByAllReferences", ByAllReferences);	
	ClosingParameters.Insert("ByOneWareroom", ByOneWareroom);
	ClosingParameters.Insert("CustomizeGenerationByWarerooms", CustomizeGenerationByWarerooms);
	
	CommonSettingsStorageSave(WarehouseIDOfPremises, ClosingParameters);
	
	ClosingParameters.Insert("WareroomToCreateGoodsIssueNotes", Premise);
	If UseWarerooms Then
		ClosingParameters.Insert("ByOneWareroom", ByOneWareroom);
		If Not ByOneWareroom Or (UseWarerooms And Not ValueIsFilled(Premise)) Then
			ClosingParameters.Insert("AssignShippingArea", False);
		EndIf;
	Else
		ClosingParameters.Insert("ByOneWareroom", False);
	EndIf;
	
	FillPropertyValues(FormOwner,ClosingParameters,
		"ShippingZone,AssignShippingArea,ByAllReferences,ByOneWareroom,WareroomToCreateGoodsIssueNotes");
	
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure PlacementWhenChangingOnServer()	
	UseBinLocationWarehousing = UseBinLocationWarehousing(Warehouse, Premise);
	Items.AssignAShippingZone.Visible = UseBinLocationWarehousing;
	Items.ShippingZone.Visible			 = UseBinLocationWarehousing;	
	
	SetDefaults();
	SetAvailability();
	
EndProcedure

&AtServerNoContext
Function UseBinLocationWarehousing(Warehouse, Premise)
	
	Return WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise)
		
EndFunction

&AtServer
Procedure SetVisibility1()
	
	Items.ByAllReferences.Visible  = (Parameters.Operation = "FormationOfOrders")
												Or (Parameters.Operation = "FormationOfOrdersAddressWarehouse");
	Items.ByAllReferences2.Visible = Items.ByAllReferences.Visible;
	Items.Settings.ShowTitle  = Items.ByAllReferences.Visible;
	
	Items.CustomizeGenerationByWarerooms.Visible  = UseWarerooms;
	Items.CustomizeGenerationByWarerooms1.Visible = UseWarerooms;
	Items.Premise.Visible                          = UseWarerooms;
	ShippingAreaVisibility                                 = (Parameters.Operation = "SelectingShippingZone")
															Or (Parameters.Operation = "FormationOfOrdersAddressWarehouse")
															Or (Parameters.Operation = "JobGeneration");
	
	Items.AssignAShippingZone.Visible = ShippingAreaVisibility;
	Items.ShippingZone.Visible			 = ShippingAreaVisibility;
	
EndProcedure

&AtServer
Procedure SetDefaults()
	
	If Not ValueIsFilled(ShippingZone) Then
		ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Warehouse,Premise);
	EndIf;
	
	If ItIsRequiredToCockAndLockAssignShipmentZone() Then
		AssignShippingArea = True;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetAvailability()
	Items.AssignAShippingZone.Enabled  = (Not UseWarerooms Or (ByOneWareroom And ValueIsFilled(Premise)));
	If ItIsRequiredToCockAndLockAssignShipmentZone() Then
		Items.AssignAShippingZone.Enabled = False;
	EndIf;
	
	Items.ShippingZone.Enabled           = AssignShippingArea And (Not UseWarerooms Or (ByOneWareroom And ValueIsFilled(Premise)));
	Items.Premise.Enabled	            = ByOneWareroom;
EndProcedure

&AtServerNoContext
Procedure CommonSettingsStorageSave(WarehouseIDOfPremises, ClosingParameters)
	
	Common.CommonSettingsStorageSave(
		"ShipmentManagementFormSettingsFormFormSettings" + WarehouseIDOfPremises,
		 "",
		ClosingParameters);
	
EndProcedure

Function ItIsRequiredToCockAndLockAssignShipmentZone()
	
	If Items.AssignAShippingZone.Visible
		And Items.Premise.Visible
		And ByOneWareroom Then
		Return True;
	ElsIf Items.AssignAShippingZone.Visible
		And Items.Premise.Visible
		And Not ByOneWareroom Then
		Return False;
	ElsIf Items.AssignAShippingZone.Visible
		And Not Items.Premise.Visible Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#EndRegion
