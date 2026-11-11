
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If TypeOf(Record.LineOfBusinessAllocationMethod) = Type("CatalogRef.LinesOfBusiness") Then
		LineOfBusinessSpecificationOption = 0;
		LineOfBusiness = Record.LineOfBusinessAllocationMethod;
	Else
		LineOfBusinessSpecificationOption = 1;
		LineOfBusinessAllocationMethod = Record.LineOfBusinessAllocationMethod;
	EndIf;
	
	If TypeOf(Record.Products) = Type("CatalogRef.Products")
	 And ValueIsFilled(Record.Products) Then
		SettingByItemItemPosition = True;
		Products = Record.Products;
		ProductSegment = Undefined;
	ElsIf TypeOf(Record.Products) = Type("CatalogRef.ProductSegments")
	 And ValueIsFilled(Record.Products) Then
		SettingUpByItemSegment = True;
		ProductSegment = Record.Products;
		Products = Undefined;
	EndIf;
	
	If TypeOf(Record.Partner) = Type("CatalogRef.Partners") 
	 And ValueIsFilled(Record.Partner) Then
		CustomizingByClient = True;
		Client = Record.Partner;
		PartnersSegment = Undefined;
	ElsIf TypeOf(Record.Partner) = Type("CatalogRef.PartnersSegments") 
	 And ValueIsFilled(Record.Partner) Then
		SettingUpByCustomerSegment = True;
		PartnersSegment = Record.Partner;
		Client = Undefined;
	EndIf;
	
	SettingUpByDivision = ValueIsFilled(Record.Department);
	SettingUpByOrganization = ValueIsFilled(Record.Organization);
	SettingUpByWarehouse = ValueIsFilled(Record.Warehouse);

	Items.WarehouseGroup_.Visible = GetFunctionalOption("UseSeveralWarehouses");
	Items.GroupProductSegment.Visible = GetFunctionalOption("UseProductSegments");
	Items.PartnerGroupSegment.Visible = GetFunctionalOption("UsePartnersSegments");
	
	SetFieldVisibility();
	SetPartnerSelectionParameters();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CustomizingByClient Then
		CurrentObject.Partner = Client;
	ElsIf SettingUpByCustomerSegment Then 
		CurrentObject.Partner = PartnersSegment;
	Else
		CurrentObject.Partner = Undefined;
	EndIf;
	If SettingByItemItemPosition Then
		CurrentObject.Products = Products;
	ElsIf SettingUpByItemSegment Then
		CurrentObject.Products = ProductSegment;
	Else
		CurrentObject.Products = Undefined;
	EndIf;
	If Not SettingUpByOrganization Then
		CurrentObject.Organization = Undefined;
	EndIf;
	If Not SettingUpByDivision Then
		CurrentObject.Department = Undefined;
	EndIf;
	If Not SettingUpByWarehouse Then
		CurrentObject.Warehouse = Undefined;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineOfBusinessSpecificationOptionOnChange(Item)
	Modified = True;
	LineOfBusinessSpecificationOptionOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	Modified = True;
	Record.LineOfBusinessAllocationMethod = LineOfBusiness;
EndProcedure

&AtClient
Procedure LineOfBusinessAllocationMethodOnChange(Item)
	Modified = True;
	Record.LineOfBusinessAllocationMethod = LineOfBusinessAllocationMethod;
EndProcedure

&AtClient
Procedure PartnersSegmentStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	AcceptableMethodsOfFormation = New Array;
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.GenerateManually"));
	FilterStructure1 = New Structure("GenerationMethod", AcceptableMethodsOfFormation);
	FormParameters = New Structure("Filter, ChoiceMode", FilterStructure1, True);
	
	OpenForm("Catalog.PartnersSegments.ChoiceForm", FormParameters, Item);
EndProcedure

&AtClient
Procedure PartnersSegmentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	AcceptableMethodsOfFormation = New Array;
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.GenerateManually"));
	DataGetParameters.Filter = New Structure("GenerationMethod", AcceptableMethodsOfFormation);
EndProcedure

&AtClient
Procedure ProductSegmentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	AcceptableMethodsOfFormation = New Array;
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.GenerateManually"));
	DataGetParameters.Filter = New Structure("GenerationMethod", AcceptableMethodsOfFormation);
EndProcedure

&AtClient
Procedure ProductSegmentStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	AcceptableMethodsOfFormation = New Array;
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
	AcceptableMethodsOfFormation.Add(PredefinedValue("Enum.SegmentGenerationMethods.GenerateManually"));
	FilterStructure1 = New Structure("GenerationMethod", AcceptableMethodsOfFormation);
	FormParameters = New Structure("Filter, ChoiceMode", FilterStructure1, True);
	
	OpenForm("Catalog.ProductSegments.ChoiceForm", FormParameters, Item);
EndProcedure

#EndRegion

#Region Private

#Region FormItemsManagement

&AtServer
Procedure SetFieldVisibility()

	If LineOfBusinessSpecificationOption = 0 Then
		Items.LineOfBusinessAllocationMethod.Enabled = False;
		Items.LineOfBusiness.Enabled = True;
	Else
		Items.LineOfBusinessAllocationMethod.Enabled = True;
		Items.LineOfBusiness.Enabled = False;
	EndIf;
	
	Items.Partner.Enabled = CustomizingByClient;
	Items.PartnersSegment.Enabled = SettingUpByCustomerSegment;
	
	Items.Products.Enabled = SettingByItemItemPosition;
	Items.ProductSegment.Enabled = SettingUpByItemSegment;
	
	Items.Warehouse.Enabled = SettingUpByWarehouse;
	Items.Department.Enabled = SettingUpByDivision;
	Items.Organization.Enabled = SettingUpByOrganization;
	
EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	
	ParametersArray = New Array;
	
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
	EndIf;
	
	Items.Partner.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure LineOfBusinessSpecificationOptionOnChangeServer()
	
	SetFieldVisibility();
	If LineOfBusinessSpecificationOption = 0
	   And TypeOf(Record.LineOfBusinessAllocationMethod) <> Type("CatalogRef.LinesOfBusiness")
	Then
		Record.LineOfBusinessAllocationMethod = Catalogs.LinesOfBusiness.EmptyRef();
		LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
	ElsIf LineOfBusinessSpecificationOption = 1
		And TypeOf(Record.LineOfBusinessAllocationMethod) <> Type("CatalogRef.AllocationMethodsByLinesOfBusiness")
	Then
		Record.LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;
	
	If LineOfBusinessSpecificationOption = 1
	   And Not ValueIsFilled(Record.LineOfBusinessAllocationMethod) Then
		Record.LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.DefaultDistributionMethod(Enums.AllocationRulesByLinesOfBusiness.InProportionToFactors);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure CustomizingByClientOnChange(Item)
	SetCustomerAvailabilityOfCustomerSegment(Item.Name);
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SettingUpByCustomerSegmentOnChange(Item)
	SetCustomerAvailabilityOfCustomerSegment(Item.Name);
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SettingByItemItemPositionOnChange(Item)
	SetAvailabilityOfItemOfInventorySegment(Item.Name);
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SettingUpByItemSegmentOnChange(Item)
	SetAvailabilityOfItemOfInventorySegment(Item.Name);
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SettingUpByWarehouseOnChange(Item)
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SettingUpByDivisionOnChange(Item)
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SettingUpByOrganizationOnChange(Item)
	SetFieldVisibility();
EndProcedure

&AtClient
Procedure SetCustomerAvailabilityOfCustomerSegment(Var_CurrentItem)
	Modified = True;
	If Var_CurrentItem = "CustomizingByClient" And CustomizingByClient Then
		SettingUpByCustomerSegment = False;
		PartnersSegment = "";
	ElsIf Var_CurrentItem = "SettingUpByCustomerSegment" And SettingUpByCustomerSegment Then
		CustomizingByClient = False;
		Client = "";
	EndIf;
EndProcedure

&AtClient
Procedure SetAvailabilityOfItemOfInventorySegment(Var_CurrentItem)
	Modified = True;
	If Var_CurrentItem = "SettingByItemItemPosition" And SettingByItemItemPosition Then
		SettingUpByItemSegment = False;
		ProductSegment = "";
	ElsIf Var_CurrentItem = "SettingUpByItemSegment" And SettingUpByItemSegment Then
		SettingByItemItemPosition = False;
		Products = "";
	EndIf;
EndProcedure

#EndRegion

#EndRegion
