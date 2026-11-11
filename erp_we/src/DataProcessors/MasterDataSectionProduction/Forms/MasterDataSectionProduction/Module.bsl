
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ManagingElements();
	
EndProcedure 

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenClassifierOfOperations(Command)
	OpenForm("Catalog.ManufacturingOperationClassifier.ListForm", , ThisObject);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OpenTypesOfTechnologicalOperations(Command)
	OpenForm("Catalog.TechnologicalOperationKinds.Form.ListForm", , ThisObject);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure TheOpenStructureOfTheEnterprise(Command)
	
	FormParameters = New Structure("ProductionUnitsOnly", True);
	OpenForm("Catalog.BusinessStructure.ListForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenCalendars(Command)
	
	OpenForm("Catalog.Calendars.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenAQueueForProductionDivisions(Command)
	
	OpenForm("Catalog.BusinessStructure.Form.SetProductionBusinessUnitPriorities", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenReasonsForDelayOfProductionStageExecution(Command)
	OpenForm("Catalog.ReasonsForProductionStageExecutionDelay.ListForm", , ThisForm);
	Return; // it is not used in KA2
	
EndProcedure

&AtClient
Procedure OpenInteroperationTransferParameters(Command)
	OpenForm("InformationRegister.InteroperationTransferParameters.ListForm", , ThisForm);
	Return; // it is not used in KA2
	
EndProcedure

&AtClient
Procedure OpenTheReasonsOfProductionCancellation(Command)
	OpenForm("Catalog.ReasonsForProductionCancellation.ListForm", , ThisForm);
	Return; // it is not used in KA2
	
EndProcedure

&AtClient
Procedure OpenOperationalPlanningModels(Command)
	OpenForm("Catalog.MESModels.ListForm", , ThisForm);
	Return; // it is not used in KA2
	
EndProcedure

&AtClient
Procedure ToOpenScenariosOfOperationalPlanning(Command)
	OpenForm("Catalog.ManufacturingExecutionSystemScenarios.ListForm", , ThisForm);
	Return; // it is not used in KA2
	
EndProcedure

&AtClient
Procedure OpenProductionStages(Command)
	OpenForm("Catalog.ProductionPhases.ListForm", , ThisForm);
	Return; // it is not used in KA2
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()
	
	EnterpriseManagement = GetFunctionalOption("EnterpriseManagement");
	
	#Region NormativeBackgroundInformation
	
	Items.OpenClassifierOfOperations.Visible = True
		And AccessRight("View", Metadata.Catalogs.ManufacturingOperationClassifier)
		And GetFunctionalOption("StoreOperationsInBillsOfMaterials")
		And EnterpriseManagement;
	
	Items.OpenTypesOfTechnologicalOperations.Visible = True
		And AccessRight("View", Metadata.Catalogs.TechnologicalOperationKinds)
		And GetFunctionalOption("UseKindsOfSpecificTechnologicalOperations")
		And EnterpriseManagement;
	
	#EndRegion
	
	#Region ProductionStructure
	
	//
	DivisionAccessRights = AccessRight("View", Metadata.Catalogs.BusinessStructure);
	Items.GroupEnterpriseStructure.Visible = DivisionAccessRights;
	
	//
	RightOfAccessWorkCenters  = False;
	RightOfAccessWorkCenters  = AccessRight("View", Metadata.Catalogs.WorkCenters);
	Items.GroupWorkCenterStructure.Visible = RightOfAccessWorkCenters And EnterpriseManagement;
	
	//
	RightToAccessCalendars = AccessRight("View", Metadata.Catalogs.Calendars);
	Items.CalendarsGroup.Visible = RightToAccessCalendars;
	
	// Group header
	Items.TheGroupProductionStructure.Visible =
		DivisionAccessRights
		Or RightOfAccessWorkCenters
		Or RightToAccessCalendars;
	#EndRegion
	
	#Region IntershopManagement
	
	Items.ToOpenTheSetupStageOfTheProductionUnits.Visible = EnterpriseManagement
		And AccessRight("View", Metadata.Catalogs.BusinessStructure);
		
	Items.GroupReasonsForDelaysInProductionStages.Visible = EnterpriseManagement
		And AccessRight("View", Metadata.Catalogs.ReasonsForProductionStageExecutionDelay)
		;
	
	Items.GroupReasonsForCancellationOfProduction.Visible = EnterpriseManagement
		And AccessRight("View", Metadata.Catalogs.ReasonsForProductionCancellation)
		;
	
	#EndRegion
	
	#Region ShopManagement
	PostoperativePlanningIsUsed = GetFunctionalOption("UseManufacturingExecutionSystem")
		;
	
	//
	LegalParametersOfInteroperableTransitions = PostoperativePlanningIsUsed
		And AccessRight("View", Metadata.InformationRegisters.InteroperationTransferParameters);
	Items.GroupParametersOfInteroperationTransitions.Visible = LegalParametersOfInteroperableTransitions;
	
	//
	LawOfPostoperativePlanningModel = PostoperativePlanningIsUsed
		And AccessRight("View", Metadata.Catalogs.MESModels);
	Items.OperationalPlanningModelGroup.Visible = LawOfPostoperativePlanningModel;
	
	//
	RightPostoperativePlanningScenarios = PostoperativePlanningIsUsed
		And AccessRight("View", Metadata.Catalogs.ManufacturingExecutionSystemScenarios);
	Items.GroupTheScenariosOfOperationalPlanning.Visible = RightPostoperativePlanningScenarios;
	Items.IntraShopManagementGroup.Visible = 
		EnterpriseManagement
		And (LegalParametersOfInteroperableTransitions
			Or LawOfPostoperativePlanningModel
			Or RightPostoperativePlanningScenarios)
			;
	#EndRegion
		
EndProcedure

#EndRegion
