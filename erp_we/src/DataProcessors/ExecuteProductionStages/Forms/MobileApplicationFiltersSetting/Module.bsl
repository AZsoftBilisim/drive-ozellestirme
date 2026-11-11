#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OnlyTheWellOff = ?(Parameters.FilterSupply = "MaterialsAreProvided", True, False);
	Department      = Parameters.Department;
	OrderDocument              = Parameters.OrderDocument;
	Product            = Parameters.Product;
	Lot             = Parameters.Lot;
	Stage               = Parameters.Stage;
	
	State = Parameters.FilterState;
	
	If State.Count() > 0 Then
		
		If State.Count() = 1 
			And State[0].Value = PredefinedValue("Enum.ShopfloorLevelStagesStates.Initiated") Then
			
			ExecutionIsAllowed = False;
			Initiated = True;
			
		Else
			ExecutionIsAllowed = True;
			Initiated = False;
		EndIf;
		
	Else
		ExecutionIsAllowed = False;
		Initiated = False;
	EndIf;
	
	GraphIsUsed_ = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	If GraphIsUsed_ Then
		Period = Parameters.Period;
	EndIf;
	
	Items.Period.Visible = GraphIsUsed_;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExecutionIsAllowedOnChange(Item)
	
	If ExecutionIsAllowed Then
		Initiated = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure InitiatedOnChange(Item)
	
	If Initiated Then
		ExecutionIsAllowed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetFilters(Command)
	
	FilterParameters = New Structure();
	
	FilterParameters.Insert("ExecutionIsAllowed", ExecutionIsAllowed);
	FilterParameters.Insert("Initiated", Initiated);
	FilterParameters.Insert("OnlyTheWellOff", OnlyTheWellOff);
	FilterParameters.Insert("FilterDepartment", Department);
	FilterParameters.Insert("FilterOrderDocument", OrderDocument);
	FilterParameters.Insert("FilterProduct", Product);
	FilterParameters.Insert("FilterLot", Lot);
	FilterParameters.Insert("FilterStage", Stage);
	FilterParameters.Insert("FilterPeriod", Period);
	
	Close(FilterParameters);
	
EndProcedure

&AtClient
Procedure ClearFilters(Command)
	
	OrderDocument         = Undefined;
	Product       = Undefined;
	Lot        = Undefined;
	Department = Undefined;
	Stage          = Undefined;
	
	Period = New StandardPeriod();
	
	OnlyTheWellOff = False;
	ExecutionIsAllowed     = False;
	Initiated              = False;
	
EndProcedure

#EndRegion
