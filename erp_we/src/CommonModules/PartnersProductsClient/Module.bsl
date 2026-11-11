
#Region Public

#Region OverridableCommands_CounterpartyProducts

// See ProductCrossReferencesMappingClientOverridable.Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures
Procedure Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(Form, Command) Export
	
	FormEventsClient.ExecuteOverridableCommand(Form, Command);
	
EndProcedure

// See ProductCrossReferencesMappingClientOverridable.Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures
Procedure Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures(Command, Form, Source) Export


EndProcedure

#Region FilesOperations

// See ProductCrossReferencesMappingClientOverridable.Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures
Procedure Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures(Form, Command) Export
	
EndProcedure

// See ProductCrossReferencesMappingClientOverridable.Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures
Procedure Attachable_PreviewFieldCheckDragging_CounterpartyNomenclatures(Form, Item, DragParameters, StandardProcessing) Export

EndProcedure

// See ProductCrossReferencesMappingClientOverridable.Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures
Procedure Attachable_PreviewFieldDrag_CounterpartyNomenclatures(Form, Item, DragParameters, StandardProcessing) Export
	
EndProcedure

// See ProductCrossReferencesMappingClientOverridable.Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures
Procedure Attachable_PreviewFieldClick_CounterpartyNomenclatures(Form, Item, StandardProcessing) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers_CounterpartyProductForms

// See ProductCrossReferencesMappingClientOverridable.AfterWriting_FormOfCounterpartyProductItem
Procedure AfterWriting_FormOfCounterpartyProductItem(Form, WriteParameters) Export
	
	ConfigurationModificationClientOverridable.AfterWrite(Form, WriteParameters);
	
EndProcedure

// See ProductCrossReferencesMappingClientOverridable.WhenOpening_FormOfCounterpartyProductItem
Procedure WhenOpening_FormOfCounterpartyProductItem(Form, Cancel) Export

EndProcedure

// See ProductCrossReferencesMappingClientOverridable.NotificationProcessing_FormOfCounterpartyProductItem
Procedure NotificationProcessing_FormOfCounterpartyProductItem(Form, EventName, Parameter, Source) Export

EndProcedure

#EndRegion

#Region OpeningForms

// Opens the price list of the supplier's item.
//
// Parameters:
//  CommandParameter            - CatalogRef.ProductCrossReferences - the nomenclature of the counterparty.
//  CommandExecuteParameters - CommandExecuteParameters                - structure passed to the command handler.
//
Procedure OpenSupplierSPriceList(CommandParameter, CommandExecuteParameters) Export

	FormParameters = New Structure;
	FormParameters.Insert("PartnerProducts", CommandParameter);
	
	OpenForm("DataProcessor.VendorPriceLists.Form.Form",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);

EndProcedure


// See ProductCrossReferencesMappingClientOverridable.OpenProductSelectionForm
Procedure OpenProductSelectionForm(Val Parameters, Val Owner, Val Uniqueness) Export
	OpenForm("Catalog.Products.ChoiceForm", 
		Parameters, Owner, Uniqueness,,,, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// Opens the partner's item list form with selection by owner, item, characteristic, and package.
//
// Parameters:
//  Partner               - CatalogRef.Partners   - owner of the supplier's item
//  Ref                - DocumentRef              - link to the document from which the procedure is called
//  CurrentRow         - FormDataCollectionItem - the current row in the Products table.
//  PartnerPresentation_ - String                      - name of the field to return the error for.
//  ListPresentation   - String
//
Procedure ShowThePartnerSNomenclature(Partner, Ref, CurrentRow, PartnerPresentation_, ListPresentation = "Goods") Export
	
	Cancel = False;
	
	If Not ValueIsFilled(Partner) Then
		Cancel = True;
	EndIf;
		
	If CurrentRow = Undefined Then
		Cancel = True;
	ElsIf Not ValueIsFilled(CurrentRow.Products) Then
		Cancel = True;
	EndIf;
	
	If Cancel Then
		
		ClearMessages();
		
		If Not ValueIsFilled(Partner) Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""%1""';
											|ru = 'Поле ""%1"" не заполнено';
											|en = 'Field %1 is required'; fa = 'Field %1 is required';
											|it = 'Il campo ""%1"" non è compilato';
											|pl = 'Pole ""%1"" nie jest wypełnione';
											|tr = '""%1"" alanı doldurulmadı'", PartnerPresentation_), Ref, "Object.Partner");
		EndIf;
		
		If CurrentRow = Undefined Then
			CommonClient.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chọn dòng bảng ""%1""';
																					|ru = 'Выберите строку таблицы ""%1""';
																					|en = 'Select a row of the ""%1"" table'; fa = 'Select a row of the ""%1"" table';
																					|it = 'Выберите строку таблицы ""%1""';
																					|pl = 'Select a row of the ""%1"" table';
																					|tr = '""%1"" tablo satırını seç'"),
					ListPresentation),
					Ref,
					StringFunctionsClientServer.SubstituteParametersToString("Object.%1", ListPresentation));
		ElsIf Not ValueIsFilled(CurrentRow.Products) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa điền cột ""Sản phẩm""';
					|ru = 'Не заполнена колонка ""Номенклатура""';
					|en = 'Column ""Items"" is not filled in'; fa = 'Column ""Items"" is not filled in';
					|it = 'La colonna ""articolo"" non è compilata';
					|pl = 'Nie wypełniono kolumny ""Номенклатура""';
					|tr = '""Öğe"" sütunu doldurulmadı'"),
				Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "Products"));
		EndIf;
		
	Else
		
		ParametersStructure = New Structure();
		ParametersStructure.Insert("ItemOwner", Partner);
		ParametersStructure.Insert("Products"        , CurrentRow.Products);
		ParametersStructure.Insert("Characteristic"      , CurrentRow.Characteristic);
		ParametersStructure.Insert("Package"            , CurrentRow.Package);
		
		OpenForm("Catalog.ProductCrossReferences.Form.ListForm",
			New Structure("Filter", ParametersStructure), , , , , , FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
	
EndProcedure

// Opens the partner's item list form with selection by owner, item, characteristic, and package.
//
// Parameters:
//  FormOwner                     - ClientApplicationForm  - owner of the form.
//  Partner                           - CatalogRef.Partners   - owner of the supplier's item
//  CurrentRow                     - FormDataCollectionItem - the current row in the Products table.
//  PresentationOfPartnerProducts - String                      - name of the field to display when opening the form.
//  ClosingNotification               - CallbackDescription          - notifications to be executed after the form is closed.
//  CustomerInvoiceServices               - Boolean                      - indicates that we are filling in the completed work.
//  AvailabilityOfSelections                - Boolean                      - indicates that Selections are available on the form.
//
Procedure OpenPartnerProductSelectionForm(FormOwner,
												Partner,
												CurrentRow,
												PresentationOfPartnerProducts,
												ClosingNotification,
												CustomerInvoiceServices = False,
												AvailabilityOfSelections = True) Export
	
	UnitOfMeasure = DefaultUnitValue(CurrentRow);
	
	FilterParameters = New Structure;
	
	If TypeOf(ClosingNotification) = Type("CallbackDescription")
		And ValueIsFilled(ClosingNotification.AdditionalParameters)
		And ClosingNotification.AdditionalParameters.Property("FormItem") Then 
		ChoiceParameters = ClosingNotification.AdditionalParameters.FormItem.ChoiceParameters;
		For Each ChoiceParameter In ChoiceParameters Do
			SeparatorPosition = StrFind(ChoiceParameter.Name, ".", SearchDirection.FromEnd);
			LengthParameterName = StrLen(ChoiceParameter.Name);
			If SeparatorPosition < LengthParameterName Then
				ParameterName = Right(ChoiceParameter.Name, LengthParameterName - SeparatorPosition);
			Else
				ParameterName = ChoiceParameter.Name;
			EndIf;
			FilterParameters.Insert(ParameterName, ChoiceParameter.Value);
		EndDo;
	EndIf;
	
	FilterParameters.Insert("ItemOwner", Partner);
	FilterParameters.Insert("Products"        , CurrentRow.Products);
	FilterParameters.Insert("Characteristic"      , CurrentRow.Characteristic);
	FilterParameters.Insert("Package"            , UnitOfMeasure);
	FilterParameters.Insert("CustomerInvoiceServices" , CustomerInvoiceServices);
	
	If TypeOf(CurrentRow) = Type("FormDataTreeItem")
		And CurrentRow.GetParent() = Undefined Then
		FilterParameters.Insert("UseCharacteristics", False);
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("FormCaption"     , PresentationOfPartnerProducts);
	ParametersStructure.Insert("ChoiceMode"        , True);
	ParametersStructure.Insert("Filter"              , FilterParameters);
	ParametersStructure.Insert("CurrentRow"      , CurrentRow.PartnerProducts);
	ParametersStructure.Insert("AvailabilityOfSelections" , AvailabilityOfSelections);
	
	OpenForm("Catalog.ProductCrossReferences.Form.ChoiceForm",
		ParametersStructure, FormOwner, , , , ClosingNotification);
	
EndProcedure

#EndRegion

#Region WorkingWithProductListOfCounterparties


// When you try to select a partner item in a table row, the user receives a message that the partner is not filled in.
//
// Parameters:
//  Object                - FormDataStructure - document for issuing error messages
//  Field                  - FormField            - field where the user makes a selection
//  NameOfFieldToCheck   - String               - name of the field to return the error for.
//  PartnerPresentation_ - String               - the representation of the field for which you want to generate an error.
//
Procedure WhenSelectingPartnerProducts(Object, Field, NameOfFieldToCheck, PartnerPresentation_) Export
	
	If Field.Name = NameOfFieldToCheck Then
		
		If Not ValueIsFilled(Object.Partner) Then
			
			ClearMessages();
			MessageText = NStr("vi = 'Chưa điền trường ""%PartnerPresentation_%""';
								|ru = 'Поле ""%PartnerPresentation_%"" не заполнено';
								|en = '""%PartnerPresentation_%"" is required'; fa = '""%PartnerPresentation_%"" is required';
								|it = 'Il campo ""%PartnerPresentation_%"" non è compilato';
								|pl = 'Pole ""%PartnerPresentation_%"" nie jest wypełnione';
								|tr = '""%PartnerPresentation_%"" alanı doldurulmadı'");
			MessageText = StrReplace(MessageText, "%PartnerPresentation_%", PartnerPresentation_);
			CommonClient.MessageToUser(MessageText, Object.Ref, "Object.Partner");
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Creates a list of the partner's item selection with selection by item, characteristic, and packaging.
//
// Parameters:
//  Partner       - CatalogRef.Partners   - owner of the supplier's item
//  CurrentRow - FormDataCollectionItem - current row in the Products table
//  ChoiceList  - ValueList of CatalogRef.ProductCrossReferences - list of supplier's item selection.
//
Procedure FillInPartnerProductSelectionList(Partner, CurrentRow, ChoiceList) Export
	
	If CurrentRow = Undefined Or Not ValueIsFilled(CurrentRow.Products)
		Or Not ValueIsFilled(Partner) Then
		ChoiceList.Clear();
	Else
		
		Package = Undefined;
		If CurrentRow.Property("Package") Then
			Package = CurrentRow.Package;
		ElsIf CurrentRow.Property("UnitOfMeasure") Then
			Package = CurrentRow.UnitOfMeasure;
		EndIf;

		ArrayOfValues = New Array();
		
		ChoiceList.LoadValues(ArrayOfValues);
		
	EndIf;
	
EndProcedure

// Sets the selection parameters of the package.
//
// Parameters:
//  ChoiceParameters - Structure             - the selection parameters of the line.
//  CurrentData   - FormDataCollectionItem - Current line.
//
Procedure SetPackageSelectionParameters(ChoiceParameters, CurrentData) Export
	
	If CurrentData = Undefined 
		Or Not ValueIsFilled(CurrentData.Products) Then
		Return;
	EndIf; 
	
	NewSelectionOptions = New Array;
	SelectionParameterKey  = "Filter.Package";
	
	For Each ChoiceParameter In ChoiceParameters Do
		If ChoiceParameter.Name <> SelectionParameterKey Then
			NewSelectionOptions.Add(ChoiceParameter);
		EndIf;
	EndDo;
	
	UnitOfMeasure = DefaultUnitValue(CurrentData);
	
	NewSelectionOptions.Add(New ChoiceParameter(SelectionParameterKey, UnitOfMeasure));
	
	ChoiceParameters = New FixedArray(NewSelectionOptions);
	
EndProcedure

// Sets the selection parameters of the package.
//
// Parameters:
//  ChoiceParameters	- Structure						- the selection parameters of the line.
//  Partner			- CatalogRef.Partners		- owner of the supplier's item.
//  CurrentData	- FormDataCollectionItem	- Current line.
//
Procedure SetFormElementSelectionParameters(ChoiceParameters, Partner, CurrentData) Export
	
	If	CurrentData = Undefined 
			Or Not ValueIsFilled(CurrentData.Products)
			Or Not ValueIsFilled(Partner) Then
		Return;
	EndIf; 
	
	NewSelectionOptions = New Array;
	NewSelectionOptions.Add(New ChoiceParameter("Filter.Owner", Partner));
	NewSelectionOptions.Add(New ChoiceParameter("Filter.Products", CurrentData.Products));
	NewSelectionOptions.Add(New ChoiceParameter("Filter.Characteristic", CurrentData.Characteristic));
	
	UnitOfMeasure = DefaultUnitValue(CurrentData);
	NewSelectionOptions.Add(New ChoiceParameter("Filter.Package", UnitOfMeasure));
	
	ChoiceParameters = New FixedArray(NewSelectionOptions);
	
EndProcedure

#EndRegion


#EndRegion

#Region Private

Function DefaultUnitValue(CurrentData)
	
	If CurrentData.Property("Package")
		And ValueIsFilled(CurrentData.Package) Then
		UnitOfMeasure = CurrentData.Package;
		
	ElsIf CurrentData.Property("UnitOfMeasure")
		And ValueIsFilled(CurrentData.UnitOfMeasure) Then
		UnitOfMeasure = CurrentData.UnitOfMeasure;
		
	Else
		UnitOfMeasure = ProductsServerCall.ProductStorageUnit(CurrentData.Products);
	EndIf;
	
	Return UnitOfMeasure;
	
EndFunction
	
#EndRegion
