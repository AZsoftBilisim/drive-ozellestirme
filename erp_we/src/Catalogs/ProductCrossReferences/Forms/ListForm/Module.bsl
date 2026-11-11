
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Filter.Property("ItemOwner") Then
		OwnerFilter = Parameters.Filter.ItemOwner;
		Items.OwnerFilter.ReadOnly = True;
	EndIf;
	
	If Parameters.Filter.Property("Products") Then
		Items.List.Representation = TableRepresentation.List;

		If Not ValueIsFilled(Parameters.Filter.Package)
			And ValueIsFilled(Parameters.Filter.Products) Then
			ProductCrossReferencesMappingOverridable.BasicUnitOfProductMeasurement(Parameters.Filter.Products, Parameters.Filter.Package);
		EndIf;
		
	EndIf;
	
	SetVisibilityOfDuplicateSearchCommand();

	SetPropertiesOfRedefinedFormElements();

	ProductCrossReferencesMappingOverridable.WhenCreatingListOfCounterpartyProductsOnServer_Form(ThisForm, Cancel, StandardProcessing);
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerFilterOnChange(Item)
	
	WhenOwnerChanges(List, OwnerFilter);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	ProductCrossReferencesMappingClientOverridable.Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures(
		ThisObject, Command, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	PartnersProductsClient.Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(ThisObject, Command);
EndProcedure

&AtClient
Procedure DuplicateObjectsDetection(Command)
	
	If DuplicateSearchIsAvailable Then
		
		ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("DuplicateObjectsDetectionClient");
		
		PathToSearchForm = ModuleDuplicateObjectsDetectionClient.DuplicateObjectsDetectionDataProcessorFormName();
		OpenForm(PathToSearchForm);
		
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetPropertiesOfRedefinedFormElements()
	
	MappingMetadata = ProductCrossReferencesMappingInternal.ProductMappingMetadata();
	
	Title = MappingMetadata.ProductsAndListPresentation;
	
	Items.OwnerFilter.Title               = MappingMetadata.OwnerOfProductItemPresentation;
	Items.ItemOwner.Title        = MappingMetadata.OwnerOfProductItemPresentation;
	Items.GroupCounterpartyData.Title     = StrTemplate(NStr("vi = 'Dữ liệu %1';
															|ru = 'Данные %1';
															|en = 'Data %1'; fa = 'Data %1';
															|it = 'Dati %1';
															|pl = 'Dane %1';
															|tr = '%1 veriler'"), Lower(MappingMetadata.OwnerOfProductInGenitiveCase));
	Items.Products.Title                = MappingMetadata.ProductObjectPresentation;
	Items.Characteristic.Title              = MappingMetadata.FeaturePresentationOfObject;
	Items.Package.Title                    = MappingMetadata.PackagingObjectPresentation;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDuplicateSearchCommand()
	
	If Common.SubsystemExists("StandardSubsystems.DuplicateObjectsDetection") Then
		DuplicateSearchIsAvailable = True;
	Else
		Items.DuplicateSearchGroup.Visible = False;	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenOwnerChanges(List, Val OwnerFilter)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "ItemOwner", OwnerFilter,,,ValueIsFilled(OwnerFilter));
		
EndProcedure

#EndRegion