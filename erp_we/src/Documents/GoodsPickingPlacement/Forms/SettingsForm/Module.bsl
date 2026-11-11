
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UnitOfMeasureForWeight   = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	SettingsOwner =  Parameters.Title;
	Operation = Parameters.Operation;
	Premise = Parameters.ParameterObject.Premise;
	Warehouse = Parameters.ParameterObject.Warehouse;
	
	WarehouseIDOfPremises = String(Warehouse.UUID()) + String(Premise.UUID());
	
	Settings = Common.CommonSettingsStorageLoad("FormSelectionPlacementFormSettingsFormSettings"+SettingsOwner+Operation+WarehouseIDOfPremises, "");
	If Settings <> Undefined Then
		If Settings.Property("ByAllReferences") And SettingsOwner = "ShipGoodsFromWarehouse" Then	
			ByAllReferences = Settings.ByAllReferences;		
		EndIf;
		If Settings.Property("RepackagingJobs") And SettingsOwner = "ShipGoodsFromWarehouse" Then	
			RepackagingJobs = Settings.RepackagingJobs; 	
		EndIf;
		If Settings.Property("ByAllProducts") And SettingsOwner = "InboundWarehouseMangement" Then	
			ByAllProducts = Settings.ByAllProducts; 	
		EndIf;
		If Settings.Property("Performer") Then	
			Performer = Settings.Performer; 	
		EndIf;
        If Settings.Property("AssignAssignee") Then	
			AssignAssignee = Settings.AssignAssignee; 	
		EndIf;
        If Settings.Property("LimitationByWeight") Then	
			LimitationByWeight = Settings.LimitationByWeight; 	
		EndIf;
		If Settings.Property("LimitationByVolume") Then	
			LimitationByVolume = Settings.LimitationByVolume; 	
		EndIf;
		If Settings.Property("LimitByWeight") Then	
			LimitByWeight = Settings.LimitByWeight; 	
		EndIf;
		If Settings.Property("LimitByVolume") Then	
			LimitByVolume = Settings.LimitByVolume; 	
		EndIf;
		If Settings.Property("PrintJobs") Then	
			PrintJobs = Settings.PrintJobs; 	
		EndIf;
		If Settings.Property("PrintToPrinter") Then	
			PrintToPrinter = Settings.PrintToPrinter; 	
		EndIf;
		If Settings.Property("CustomizeGenerationByWorkAreas") Then	
			CustomizeGenerationByWorkAreas = Settings.CustomizeGenerationByWorkAreas; 	
		EndIf;
		If Settings.Property("WarehouseZone") Then	
			WarehouseZone = Settings.WarehouseZone; 	
		EndIf;
	EndIf;
	
	SetDefaults();
	
	If CustomizeGenerationByWorkAreas = "CustomizeGenerationByWorkAreas" Then
		FillIn_WorkAreaRestrictions();
	EndIf;
	
	SetVisibility1();
	SetAvailability();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseZoneOnChange(Item)
	WarehouseZoneOnChangeServer();	
EndProcedure

&AtClient
Procedure LimitByVolumeOnChange(Item)
	Items.GroupVolumeLimit.Enabled = LimitByVolume;
EndProcedure

&AtClient
Procedure LimitByWeightOnChange(Item)
	Items.GroupWeightRestriction.Enabled = LimitByWeight;
EndProcedure

&AtClient
Procedure AssignAPerformerOnChange(Item)
	Items.Performer.Enabled		   	= AssignAssignee;
EndProcedure

&AtClient
Procedure PrintJobsOnChange(Item)
	Items.PrintToPrinter.Enabled		= PrintJobs;
EndProcedure

&AtClient
Procedure CustomizeGenerationByWorkAreasOnChange(Item)
	If CustomizeGenerationByWorkAreas = "ByASingleWarehouseZone"
		And ValueIsFilled(WarehouseZone) Then
		WarehouseZoneOnChangeServer();
	Else
		SetAvailability();
	EndIf;
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
	MessageTemplate = NStr("vi = 'Chưa điền trường ""%FieldName%"".';
							|ru = 'Поле ""%FieldName%"" не заполнено.';
							|en = '""%FieldName%"" is required.'; fa = '""%FieldName%"" is required.';
							|it = 'Il campo ""%FieldName%"" non è compilato.';
							|pl = 'Nie wypełniono pola ""%FieldName%"".';
							|tr = '""%FieldName%"" alanı doldurulmamış.'");
	
	If Items.SelectionTaskSettings.Visible Then
		
		If CustomizeGenerationByWorkAreas = "ByASingleWarehouseZone" 
			And Not ValueIsFilled(WarehouseZone) Then
			
			MessageText = StrReplace(MessageTemplate,"%FieldName%",NStr("vi = 'Khu vực làm việc';
																		|ru = 'Рабочий участок';
																		|en = 'Warehouse area'; fa = 'ناحیه انبار';
																		|it = 'Area operativa';
																		|pl = 'Obszar roboczy';
																		|tr = 'Çalışma alanı'"));
			CommonClientServer.MessageToUser(MessageText,,"WarehouseZone");
			
			CheckError = True;
		EndIf;
		
	EndIf;
		
	If Items.SelectionTaskSettings.Visible Then
		
		If LimitByWeight
			And Not ValueIsFilled(LimitationByWeight)
			And (Not CustomizeGenerationByWorkAreas = "GroupByWarehouseZones") Then
			
			MessageText = StrReplace(MessageTemplate,"%FieldName%",NStr("vi = 'Hạn chế theo trọng lượng';
																		|ru = 'Ограничение по весу';
																		|en = 'Weight limit'; fa = 'سقف وزن';
																		|it = 'Limitazione per peso';
																		|pl = 'Ograniczenie wagi';
																		|tr = 'Ağırlığa göre kısıtlama'"));
			CommonClientServer.MessageToUser(MessageText,,"LimitationByWeight");
			
			CheckError = True;
		EndIf;
		
		If LimitByVolume
			And Not ValueIsFilled(LimitationByVolume)
			And (Not CustomizeGenerationByWorkAreas = "GroupByWarehouseZones") Then
			
			MessageText = StrReplace(MessageTemplate,"%FieldName%",NStr("vi = 'Hạn chế theo thể tích';
																		|ru = 'Ограничение по объему';
																		|en = 'Limitation on volume'; fa = 'محدودیت حجم';
																		|it = 'Limitazione per volume';
																		|pl = 'Ograniczenie objętości';
																		|tr = 'Hacme göre kısıtlama'"));
			CommonClientServer.MessageToUser(MessageText,,"LimitationByVolume");
			
			CheckError = True;
		EndIf;
		
	EndIf;
	
	If Items.PerformerGroup.Visible 
		And AssignAssignee
		And Not ValueIsFilled(Performer) Then
		
		MessageText = StrReplace(MessageTemplate,"%FieldName%",NStr("vi = 'Người thực hiện';
																	|ru = 'Исполнитель';
																	|en = 'Assignee'; fa = 'Assignee';
																	|it = 'Esecutore';
																	|pl = 'Wykonawca';
																	|tr = 'Atanan'"));
		CommonClientServer.MessageToUser(MessageText,,"Performer");
		
		CheckError = True;
		
	EndIf;
	
	If CheckError Then
		Return;
	EndIf;
	
	FormOwnerExtended = FormOwner;
	
	If Items.ByAllReferences.Visible Then  
		FormOwnerExtended.ByAllReferences = ByAllReferences;
		FormOwnerExtended.RepackagingJobs = RepackagingJobs;	
	ElsIf Items.ByAllProducts.Visible Then
		FormOwnerExtended.ByAllProducts = ByAllProducts;
	EndIf;
	
	FormOwnerExtended.AssignAssignee = AssignAssignee;
	If AssignAssignee Then
		FormOwnerExtended.Performer = Performer;
	Else 
		FormOwnerExtended.Performer = PerformerIsEmpty;
	EndIf;

	If Items.SelectionTaskSettings.Visible Then
		FormOwnerExtended.CustomizeGenerationByWorkAreas = CustomizeGenerationByWorkAreas;	
		FormOwnerExtended.LimitationByWeight = LimitationByWeight;
		FormOwnerExtended.LimitationByVolume = LimitationByVolume;
		FormOwnerExtended.LimitByWeight = LimitByWeight;
		FormOwnerExtended.LimitByVolume = LimitByVolume;
		FormOwnerExtended.WarehouseZone = WarehouseZone;
	EndIf;
	
	If Items.PrintJobs.Visible Then
		FormOwnerExtended.PrintJobs = PrintJobs;		
	EndIf;
	If Items.PrintToPrinter.Visible Then
		FormOwnerExtended.PrintToPrinter = PrintToPrinter;		
	EndIf;	
	
	WarehouseIDOfPremises = String(Warehouse.UUID()) + String(Premise.UUID());

	ClosingParameters = New Structure;
	ClosingParameters.Insert("ByAllReferences",ByAllReferences);
	ClosingParameters.Insert("RepackagingJobs", RepackagingJobs);
	ClosingParameters.Insert("ByAllProducts", ByAllProducts);
	ClosingParameters.Insert("AssignAssignee", AssignAssignee);
	ClosingParameters.Insert("Performer", Performer);
	ClosingParameters.Insert("CustomizeGenerationByWorkAreas", CustomizeGenerationByWorkAreas);
	ClosingParameters.Insert("LimitationByWeight", LimitationByWeight);
	ClosingParameters.Insert("LimitationByVolume", LimitationByVolume);
	ClosingParameters.Insert("LimitByWeight", LimitByWeight);
	ClosingParameters.Insert("LimitByVolume", LimitByVolume);
    ClosingParameters.Insert("WarehouseZone", WarehouseZone);
	ClosingParameters.Insert("PrintJobs", PrintJobs);
	ClosingParameters.Insert("PrintToPrinter", PrintToPrinter);
	
	CommonSettingsStorageSave(SettingsOwner, Operation, WarehouseIDOfPremises, ClosingParameters);
	
	Close(DialogReturnCode.OK);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure CommonSettingsStorageSave(SettingsOwner, Operation, WarehouseIDOfPremises, ClosingParameters)
	
	Common.CommonSettingsStorageSave(
		"FormSelectionPlacementFormSettingsFormSettings" + SettingsOwner + Operation + WarehouseIDOfPremises,
		 "",
		ClosingParameters);
	
EndProcedure

&AtServer
Procedure WarehouseZoneOnChangeServer()
	FillIn_WorkAreaRestrictions();
	SetAvailability();
EndProcedure

&AtServer
Procedure FillIn_WorkAreaRestrictions()
	AttributesValues = Common.ObjectAttributesValues(WarehouseZone,
		"LimitByWeight,LimitationByWeight,LimitByVolume,LimitationByVolume");
		
	FillPropertyValues(ThisForm, AttributesValues); 
EndProcedure

&AtServer
Procedure SetVisibility1()

	Items.SelectionTaskSettings.Visible 	= (Operation = "JobGeneration")
												   Or (Operation = "RepackagingJobs");
	Items.ByAllReferences.Visible 	    = (SettingsOwner = "ShipGoodsFromWarehouse")
													And ((Operation = "JobGeneration")
	                                               Or (Operation = "RepackagingJobs")
												   Or (Operation = "FormationOfOrders")
												   Or (Operation = "FormationOfOrdersAddressWarehouse"));
												   
	Items.ByAllProducts.Visible 	    = (SettingsOwner = "InboundWarehouseMangement")
													And ((Operation = "JobGeneration")
	                                               Or (Operation = "RepackagingJobs")
												   Or (Operation = "FormationOfOrders")
												   Or (Operation = "FormationOfOrdersAddressWarehouse"));
												   
	Items.PerformerGroup.Visible 		= (Operation = "JobGeneration") 
												   Or (Operation = "RepackagingJobs")	
												   Or (Operation = "TakingTasksToWork")
												   Or (Operation = "CompletingTasks");
	Items.PrintJobs.Visible 			= (Operation = "TakingTasksToWork");
	Items.PrintToPrinter.Visible          = (Operation = "TakingTasksToWork");
												  
	Items.RepackagingGroup.Visible 	= (SettingsOwner = "ShipGoodsFromWarehouse")
												   And (Operation = "JobGeneration");
	//
											
	If Not WarehousesServer.UseWarehouseZones(Warehouse, Premise) Then
		Items.GroupSettingsByWorkArea.Visible = False;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetDefaults()
	
	If Not ValueIsFilled(WarehouseZone) Then
		WarehouseZone = Catalogs.WarehouseZones.DefaultWorkArea(Warehouse,Premise);
	EndIf;
	
	If Not ValueIsFilled(CustomizeGenerationByWorkAreas)
		Or Not WarehousesServer.UseWarehouseZones(Warehouse, Premise) Then
		CustomizeGenerationByWorkAreas = "WithoutBreakdownByWarehouseZones";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailability()
	Items.WarehouseZone.Enabled 			= CustomizeGenerationByWorkAreas = "ByASingleWarehouseZone";
	Items.GroupVolumeLimit.Enabled 	= LimitByVolume;
	Items.GroupWeightRestriction.Enabled   	= LimitByWeight;
	Items.Performer.Enabled		   		= AssignAssignee;
	Items.PrintToPrinter.Enabled			= PrintJobs;
	
	If CustomizeGenerationByWorkAreas = "GroupByWarehouseZones" Then
		Items.GroupSettingsRightRestrictions.CurrentPage = Items.PageLimitLabel;
		Items.GroupSettingsLeftRestrictions.CurrentPage  = Items.PageLimitEmpty;
	Else
		Items.GroupSettingsRightRestrictions.CurrentPage = Items.PageLimitCheckBoxes;
		Items.GroupSettingsLeftRestrictions.CurrentPage  = Items.PageLimitFields;
	EndIf;
EndProcedure

#EndRegion
