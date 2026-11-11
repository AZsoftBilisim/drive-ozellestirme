
#Region Public

// Deletes all partners available to the user in the list and is positioned on the directory element.
//
// Parameters:
//  Form          -  ClientApplicationForm - The Form for which actions are performed contains:
//    * Items - FormAllItems - Contains:
//      ** List - FormTable - .
//  ChoiceParameter - Structure - contains selection data.
//  Empty references-Structure-contains cached values that are received on the server and required on the client.
//
Procedure ProcessPartnerSelectionViaNewPartnerInputAssistant(Form,ChoiceParameter) Export
	
	DeleteArrayOfUnavailableSelections = New Array;
	For Each FilterElement In TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items Do
		If TypeOf(FilterElement) <> Type("DataCompositionFilterItem") Then
			Continue;
		EndIf;
		If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
			If  FilterElement.LeftValue = New DataCompositionField("Segment") Then
				DeleteArrayOfUnavailableSelections.Add("Segment");
				Form.Segment = PredefinedValue("Catalog.PartnersSegments.EmptyRef");
			ElsIf FilterElement.LeftValue = New DataCompositionField("Search") Then
				DeleteArrayOfUnavailableSelections.Add("Search");
				Form.SearchString = "";
				Form.AdvancedSearch = False;
			ElsIf FilterElement.LeftValue = New DataCompositionField("MainManager") And FilterElement.RightValue <> ChoiceParameter.MainManager Then
				DeleteArrayOfUnavailableSelections.Add("MainManager");
				Form.OnlyMine = False;
			ElsIf FilterElement.LeftValue = New DataCompositionField("BusinessRegion") And FilterElement.RightValue <> ChoiceParameter.MainManager Then
				DeleteArrayOfUnavailableSelections.Add("BusinessRegion");
				Form.BusinessRegion = PredefinedValue("Catalog.BusinessRegions.EmptyRef");
			EndIf;
		Else
			FilterElement.Use = False;
		EndIf;
	EndDo;
	For Each ArrayElement In DeleteArrayOfUnavailableSelections Do
		CommonClientServer.DeleteDynamicListFilterGroupItems(Form.List, ArrayElement);
	EndDo;
	
	Form.Items.List.CurrentRow = ChoiceParameter.Partner;
	
EndProcedure

// The procedure forms the name of the partner / counterparty based on the full (legal) name.
//
// Parameters:
//  Description  - String - working name of the partner / counterparty.
//  DescriptionFull  - String - full (legal) name.
//
Procedure AbbreviatedLegalEntityNameWhenChanged(Description, DescriptionFull) Export
	
	If IsBlankString(DescriptionFull) Then
		
		Description = "";
		Return;
		
	EndIf;
	
	StartingPositionOfQuotes = 0;
	EndQuotePosition  = 0;
	
	ArrayOfTypesOfQuotes = New Array;
	ArrayOfTypesOfQuotes.Add("""");
	ArrayOfTypesOfQuotes.Add("'");
	ArrayOfTypesOfQuotes.Add("«");

	For Each TypeOfQuotationMark In ArrayOfTypesOfQuotes Do
		
		QuotationMarkTypePosition = StrFind(DescriptionFull, TypeOfQuotationMark);
		If QuotationMarkTypePosition > 0 And (StartingPositionOfQuotes = 0 Or QuotationMarkTypePosition < StartingPositionOfQuotes) Then
			StartingPositionOfQuotes = QuotationMarkTypePosition;
		EndIf;
		
	EndDo;
	
	ArrayOfTypesOfQuotes[2] ="»";
	For Each TypeOfQuotationMark In ArrayOfTypesOfQuotes Do
		
		QuotationMarkTypePosition = StrFind(DescriptionFull, TypeOfQuotationMark, SearchDirection.FromEnd);
		If QuotationMarkTypePosition > 0 And (EndQuotePosition = 0 Or QuotationMarkTypePosition > EndQuotePosition) Then
			EndQuotePosition = QuotationMarkTypePosition;
		EndIf;
		
	EndDo;
	
	If StartingPositionOfQuotes = 0 Then
		Description = DescriptionFull;
	ElsIf EndQuotePosition = 0 Then
		Description = Right(DescriptionFull, StrLen(DescriptionFull) - StartingPositionOfQuotes);
	Else
		Description = Mid(DescriptionFull, StartingPositionOfQuotes + 1, EndQuotePosition - StartingPositionOfQuotes-1);
	EndIf;
	
EndProcedure

// Opens the dialog for selecting the head counterparty for a separate business unit.
// First, an attempt will be made to search by INN and a dialog will be offered to select from the found ones.
// If the user refuses to choose, the dialog for creating a head counterparty will be called.
//
// Parameters:
//  Form  -  ClientApplicationForm - the form from which the form is called.
//  FillParameters  -Structure - structure containing the details of the subordinate counterparty.
//  SaveChanges  - Boolean - the need to install the selected head counterparty in the subordinate.
//  CompletionNotification  - CallbackDescription - additional processing in the form of a challenge.
//
Procedure FillInTheHeadCounterparty(Form, FillParameters, SaveChanges, CompletionNotification = Undefined) Export
	
	// Getting the default parameter structure
	Parameters = New Structure;
	Parameters.Insert("Counterparty",                           Undefined);
	Parameters.Insert("Partner",                              Undefined);
	Parameters.Insert("UsePartnersAsCounterparties", False);
	PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(Parameters);
	
	TMCommonUseClientServer.SupplementStructure(Parameters, FillParameters, True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", Parameters);
	AdditionalParameters.Insert("SaveChanges", SaveChanges);
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New CallbackDescription("SelectMainCounterpartyCompletion", ThisObject, AdditionalParameters);
	FormParameters = New Structure("Counterparty", Parameters.Counterparty);
	PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(FormParameters, Parameters);
	OpenForm("Catalog.Counterparties.Form.SelectMainCounterparty",
		FormParameters,
		Form, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Completion of the modal selection of the head counterparty
// if the counterparty is not selected, its creation is started. otherwise, we proceed to the selection completion procedure.
//
// Parameters:
//  ValueSelected  - CatalogRef.Counterparties - the value of the selected head contractor
//  AdditionalParameters  -Structure - structure with properties:
//   * FillParameters    - Structure - filling data for creating a lead counterparty
//   * Form                  - ClientApplicationForm - the form from which the procedure is started
//   * SaveChanges     - Boolean - record the selected head counterparty in a separate division
//   * CompletionNotification   - CallbackDescription - will be called at the End of the procedure.
//
Procedure SelectMainCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		
		If Not ValueIsFilled(ValueSelected) Then
		
			Notification = New CallbackDescription("CreationOfHeadCounterpartyCompletion", ThisObject, AdditionalParameters);
			
			FormParameters = New Structure;
			FillingValues = New Structure;
			FillParameters = AdditionalParameters.FillParameters;
			
			If FillParameters.UsePartnersAsCounterparties Then
				FormName = "Catalog.Partners.Form.WizardOfNew";
			Else
				FormName = "Catalog.Counterparties.ObjectForm";
				FillingValues.Insert("Partner", FillParameters.Partner);
			EndIf;
			FillingValues.Insert("LegalEntityIndividual", PredefinedValue("Enum.LegalEntityIndividual.Entity"));
			PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(FillingValues, FillParameters);
		
			FormParameters.Insert("FillingValues", FillingValues);
			FormParameters.Insert("BasisSeparateCounterparty", FillParameters.Counterparty);
			
			OpenForm(FormName, FormParameters,
				AdditionalParameters.Form, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
			
		Else
			
			CreationOfHeadCounterpartyCompletion(ValueSelected, AdditionalParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The modal completion of the creation of the head contractor
// If the head counterparty is created, it is set in the details of the subordinate, if this is specified in the parameters.
//
// Parameters:
//  ValueSelected        - CatalogRef.Counterparties - the value of the selected head contractor
//  AdditionalParameters  - Structure - structure with properties:
//   * FillParameters    - Structure - filling data for creating a lead counterparty
//   * Form                  - ClientApplicationForm - the form from which the procedure is started
//   * SaveChanges     - Boolean - record the created head counterparty in a separate division
//   * CompletionNotification   - CallbackDescription - will be called at the End of the procedure.
//
Procedure CreationOfHeadCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	CompletionNotification = AdditionalParameters.CompletionNotification;
	
	FillParameters = AdditionalParameters.FillParameters;
	
	If ValueSelected <> Undefined
		And AdditionalParameters.SaveChanges
		And ValueIsFilled(FillParameters.Counterparty) Then
		
		ErrorDescription = "";
		
		PartnersAndCounterpartiesLocalizationServerCall.ChangeHeadCounterparty(
			FillParameters.Counterparty, ValueSelected, ErrorDescription);
		
		If ValueIsFilled(ErrorDescription) Then
			ShowMessageBox(, ErrorDescription);
			ValueSelected = Undefined;
		EndIf
		
	EndIf;
		
	If CompletionNotification <> Undefined Then
		RunCallback(CompletionNotification, ValueSelected);
	EndIf;
	
EndProcedure

Procedure OutputUserMessage(MessageText, OnlyPartnersAreUsed, Field="", ClearMessages = False) Export
	
	If ClearMessages Then
		ClearMessages();
	EndIf;
	
	If OnlyPartnersAreUsed Then
		MessageText = StrReplace(MessageText, NStr("vi = 'bạn hàng';
													|ru = 'партнера';
													|en = 'partner'; fa = 'شریک تجاری';
													|it = 'del partner';
													|pl = 'partnera';
													|tr = 'iş ortağının'"), NStr("vi = 'đối tác';
																			|ru = 'контрагента';
																			|en = 'counterparty'; fa = 'طرف حساب';
																			|it = 'controparte';
																			|pl = 'kontrahenta';
																			|tr = 'cari hesabın'"));
	EndIf;
	
	CommonClientServer.MessageToUser(MessageText,, Field);
	
EndProcedure

#Region GeneralProceduresAndFunctionsOfListAndCatalogSelectionForms

// Called from the "Drag and drop" event handler for the navigation bar of various forms of the partner list.
// Parameters:
//  WrittenItemsCount     - Number                   - the number of elements to change in the Partners directory.
//  Item                  - FormField               - the element where the event occurs.
//  DragParameters  - DragParameters - contains drag and drop parameters.
//  StandardProcessing     - Boolean                  - indicates whether standard event processing is being performed.
//  String                   - ValueTableRow   - the line over which the cursor is located.
//  Field                     - FormField               - the managed form element that this table column is associated with.
//
Procedure FiltersNavigationBarDragAndDrop(WrittenItemsCount, Item, DragParameters, StandardProcessing, String, Field) Export
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		
		PartnersAndCounterpartiesServerCall.UpdatePropsValueForDraggedPartners(String, DragParameters.Value, WrittenItemsCount);
		
	ElsIf TypeOf(DragParameters.Value) = Type("CatalogRef.Partners") Then
		
		ArrayOfPartners = New Array;
		ArrayOfPartners.Add(DragParameters.Value);
		PartnersAndCounterpartiesServerCall.UpdatePropsValueForDraggedPartners(String, ArrayOfPartners, WrittenItemsCount);
		
	EndIf;
	
EndProcedure

// Called from the handler of the "drag Check" event in the navigation bar of various forms of the partner list.
// Parameters:
//  Form                    - ClientApplicationForm - the form in which the event occurs.
//  Item                  - FormField                  - the element where the event occurs.
//  DragParameters  - DragParameters    - contains drag and drop parameters.
//  StandardProcessing     - Boolean                     - indicates whether standard event processing is being performed.
//  String                   - ValueTableRow      - the line over which the cursor is located.
//  Field                     - FormField                  - the managed form element that this table column is associated with.
//
Procedure FiltersNavigationBarDragCheck(Form, Item, DragParameters, StandardProcessing, String, Field) Export
	
	If (String = Undefined) Or (DragParameters.Value = Undefined) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		
		For Each ArrayElement In DragParameters.Value Do

			If TypeOf(ArrayElement) = Type("CatalogRef.Partners") Then
				
				Return;
				
			EndIf;
			
			DragParameters.Action = DragAction.Cancel;
			
		EndDo;
		
		DragParameters.Action = DragAction.Cancel;
		
	ElsIf TypeOf(DragParameters.Value) = Type("CatalogRef.Partners") Then
		
		Return;
		
	Else
		
		DragParameters.Action = DragAction.Cancel;
		
	EndIf;
	
EndProcedure

// Called from the event handler "when changing" the navigation bar of various forms of the partner list.
// Parameters:
//  Form                                - ClientApplicationForm - the form in which the event occurs.
//  Item                              - FormField                  - the element where the event occurs.
//  PropertyPageNeedsFilling   - Boolean                     - indicates that the property page needs to be refilled.
//
Procedure FiltersNavigationBarFilterTypeWhenChanged(Form, Item, PropertyPageNeedsFilling) Export
	
	If TypeOf(Form.FilterType_) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo")
		And Form.CurrentPropertyOfNavigationPanel = Form.FilterType_
		And Form.Items.PagesFilterType.CurrentPage = Form.Items.PropertiesPage Then
		Return;
	ElsIf Form.FilterType_ = "Categories" And Form.Items.PagesFilterType.CurrentPage = Form.Items.CategoriesPage Then
		Return;
	ElsIf Form.FilterType_ = "BusinessRegions" And Form.Items.PagesFilterType.CurrentPage = Form.Items.PageBusinessRegions Then
		Return;
	ElsIf Form.FilterType_ = "AccessGroups" And Form.Items.PagesFilterType.CurrentPage = Form.Items.PageAccessGroups Then
		Return;
	ElsIf Form.FilterType_ = "Manager" And Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers Then
		Return;
	EndIf;
	
	SaveNavigationBarSettings(Form);
	
	If TypeOf(Form.FilterType_) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo")
		Or Form.FilterType_  = "Categories" Then
		PropertyPageNeedsFilling = True;
	ElsIf Form.FilterType_  = "BusinessRegions" Then
		Form.Items.PagesFilterType.CurrentPage = Form.Items.PageBusinessRegions; 
	ElsIf Form.FilterType_ = "AccessGroups" Then
		Form.Items.PagesFilterType.CurrentPage = Form.Items.PageAccessGroups;
	ElsIf Form.FilterType_ = "Manager" Then
		Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers;
		Form.OnlyMine = False;
		
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "OnlyMine","Enabled", Form.FilterType_ <> "Manager");
	
EndProcedure

// Called from the "when closing" event handler for various forms of the partner list.
// Parameters:
//  Form                - ClientApplicationForm          - the form in which the event occurs.
//
Procedure FormOfSelectionListWhenClosing(Form) Export
	
	 SaveNavigationBarSettings(Form);
	
EndProcedure

// Manages the availability of the "Partners" directory list forms.
// Parameters:
//  Form                - ClientApplicationForm - The Form in which the Command is executed contains:
//   * Items - FormAllItems - Contains:
//     ** FilterType_             - FormField - 
//     ** BusinessRegions          - FormTable - 
//     ** PartnerAccessGroups - FormTable - 
//     ** OnlyImportant         - FormField - 
//     ** Managers              - FormTable - 
//     ** OnlyMine              - FormField -
//
Procedure NavigationBarManageAccessibility(Form) Export

	Form.Items.FilterType_.Enabled             = Form.UseAFilter;
	Form.Items.BusinessRegions.Enabled          = Form.UseAFilter;
	Form.Items.PartnerAccessGroups.Enabled = Form.UseAFilter;
	Form.Items.Managers.Enabled              = Form.UseAFilter;
	Form.Items.OnlyImportant.Enabled         = Form.UseAFilter 
	                                                    And Not (TypeOf(Form.FilterType_) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo") 
	                                                          Or Form.FilterType_  = "Categories");
	Form.Items.OnlyMine.Enabled              = Not Form.UseAFilter Or Not Form.FilterType_ = "Manager";
	
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "FormCopy1", "Visible", Form.SimplifiedInputAvailable);
	
EndProcedure

// Fills in the form element with the contact information value in the information panel of the Partners directory list form.
// Parameters:
//  Form                    - ClientApplicationForm - the form to fill in.
//  ContactInformationKind  - CatalogRef.ContactInformationKinds - the type of CI whose value is set.
//  StructureOfData          - Structure - structure that contains the KEY.
//
Procedure FillInContactInformationElement(Form, ContactInformationKind, StructureOfData) Export
	
	If StructureOfData = Undefined Then
		Return;
	EndIf;
	
	RowData = ContactInformationLineDataByType(Form, ContactInformationKind);
	If RowData = Undefined Then
		Return;
	EndIf;
	RowData.Presentation = StructureOfData.Presentation;
	RowData.Value = StructureOfData.ContactInformation;
	Form[RowData.AttributeName] = StructureOfData.Presentation;
	
EndProcedure

// Retrieves the partner's contact information stored in the form table.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form that contains the data table.
//  ContactInformationKind - CatalogRef.ContactInformationKinds - the type of contact information for which
//                                                                        data is obtained.
//
// Returns:
//   FormDataCollectionItem   - a string with contact information data.
//
Function ContactInformationLineDataByType(Form, ContactInformationKind) Export
	
	Filter  = New Structure("Kind, IsHistoricalContactInformation", ContactInformationKind, False);
	Rows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	Return ?(Rows.Count() = 0, Undefined, Rows[0]);
	
EndFunction

Procedure FillInBaseLine(Form) Export
	
	Basis = Form.Basis1.FindRows(New Structure("Partner", LinkToListLinePartner(Form)));
	If Basis.Count() = 0 Then
		Form.SelectionBasis = "";
	Else
		Form.SelectionBasis = Basis[0].Basis;
	EndIf;
	
EndProcedure

// Checks whether positioning is performed correctly in the dynamic list.
// 
// Parameters:
//  ListName - String - name of the form element that is being checked.
//  Form     - ClientApplicationForm - a form that contains a dynamic list of partners.
//
// Returns:
//   FilterItem   - the selection group created.
//
Function PositioningIsCorrect(ListName, Form) Export

	GroupingType = Type("DynamicListGroupRow");
	
	List = Form.Items[ListName]; // FormTable
		
	If TypeOf(List.CurrentRow) <> GroupingType And ValueIsFilled(List.CurrentRow) Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

// Called from various forms of the partners directory list when you click on the Contractors hyperlink in the information panel.
// Parameters:
//  Form - ClientApplicationForm - The Form in which the Command is executed contains:
//    * Items - FormAllItems - Contains:
//      ** List - FormTable - .
//
Procedure PartnerCounterpartiesClick(Form) Export
	
	If PositioningIsCorrect("List",Form) Then
		
		FormParameters = New Structure("FilterOfCounterparties", Form.Items.List.CurrentRow);
		
	Else
		
		Return;
		
	EndIf;
	
	OpenForm(
		"Catalog.Counterparties.Form.ParametricListForm",
		FormParameters,
		Form);
		
	Notify("UpdateCatalogList", FormParameters, Form);
	
EndProcedure

// Called from various forms of the "Partners" directory list when you click on the "Contact persons" hyperlink in
// the information panel.
//  Parameters:
//  Form                - ClientApplicationForm - the form in which the command is executed.
//
Procedure ContactPersonsOfPartnerClick(Form) Export
	
	If PositioningIsCorrect("List", Form) Then
		
		If StrOccurrenceCount(Form.FormName, "Counterparties") > 0 Then
			Filter = New Structure("Owner", Form.Items.List.CurrentData.Partner);
		Else
			Filter = New Structure("Owner", Form.Items.List.CurrentRow);
		EndIf;
		
		FormParameters = New Structure("Filter", Filter);
		
	Else
		
		Return;
		
	EndIf;

	OpenForm(
		"Catalog.ContactPersonsForPartners.ListForm",
		FormParameters,
		Form);
		
	Notify("UpdateCatalogList", FormParameters, Form);
	
EndProcedure

// LongDesc
// 
// Parameters:
//  Form - ClientApplicationForm - Contains:
//   * Items - FormAllItems - Contains:
//     ** List - FormTable - .
//    
Procedure RestoreListDisplayAfterFullTextSearch(Form) Export
	
	If Form.AdvancedSearch 
	     And String(Form.Items.List.Representation) <> Form.DisplayModeBeforeApplyingFullTextSearch Then
		If Form.DisplayModeBeforeApplyingFullTextSearch = NStr("vi = 'Danh sách phân nhánh';
																|ru = 'Иерархический список';
																|en = 'Hierarchical list'; fa = 'فهرست سلسله‌مراتبی';
																|it = 'Elenco gerarchico';
																|pl = 'Lista hierarchiczna';
																|tr = 'Hiyerarşik liste'") Then
			Form.Items.List.Representation = TableRepresentation.HierarchicalList;
		ElsIf Form.DisplayModeBeforeApplyingFullTextSearch = NStr("vi = 'Cây';
																	|ru = 'Дерево';
																	|en = 'Tree'; fa = 'درخت';
																	|it = 'Diagramma ad albero';
																	|pl = 'Tree';
																	|tr = 'Ağaç'") Then
			Form.Items.List.Representation = TableRepresentation.Tree;
		EndIf;
	EndIf;
	
EndProcedure

// Called from the event handler "notification Processing" of various forms of the partner list.
// Parameters:
//  Form                               - ClientApplicationForm  - the form in which the event occurs.
//  EventName                          - String            - name of the event to process.
//  Parameter                            - Arbitrary      - notification parameter.
//  Source                            - Arbitrary      - source of the alert.
//  InformationPanelUpdateRequired - Boolean            - determines whether to update the information panel for
//                                                            the current partner.
//
Procedure PartnersSelectionListFormNotificationProcessing(Form, EventName, Parameter, Source, InformationPanelUpdateRequired) Export
	
	If EventName = "ChoosingPartnerFound" And Parameter.Property("Partner") Then
		
		ProcessPartnerSelectionViaNewPartnerInputAssistant(Form, Parameter);
		
	ElsIf EventName = "Write_ContactPersonsForPartners" And  Parameter.Property("Owner") Then
			
		CurrentData = Form.Items.List.CurrentData;
		If CurrentData <> Undefined 
			And ((CurrentData.Property("Ref") And CurrentData["Ref"] = Parameter.Owner)
			Or CurrentData.Property("Partner") And CurrentData["Partner"] = Parameter.Owner) Then
			InformationPanelUpdateRequired = True;
		EndIf;
		
	ElsIf EventName = "Write_Counterparties" And Parameter.Property("Partner") Then
		
		CurrentData = Form.Items.List.CurrentData;
		If CurrentData <> Undefined And CurrentData["Ref"] = Parameter.Partner Then
			InformationPanelUpdateRequired = True;
		EndIf;
		
	ElsIf EventName = "Write_Partners" Then
	
		CurrentData = Form.Items.List.CurrentData;
		If CurrentData <> Undefined 
			And ((CurrentData.Property("Ref") And CurrentData["Ref"] = Parameter)
			Or CurrentData.Property("Partner") And CurrentData.Partner = Parameter)Then
			InformationPanelUpdateRequired = True;
		EndIf;
		
	ElsIf EventName ="FullTextSearchModeChanged" Then
		
		Form.Close();
		
	EndIf;
	
EndProcedure

// Called from various forms of the Partners directory list when clicking on the base hyperlink.
// Parameters:
//  Form                - ClientApplicationForm - the form in which the command is executed.
//  Item              - FormItems    - the element where the action is performed.
//  StandardProcessing - Boolean           - indicates whether standard event processing is being performed.
//
Procedure PartnersSelectionListFormSelectionBasePressing(Form, Item, StandardProcessing) Export
	
	StandardProcessing = False;
	Basis = Form.Basis1.FindRows(New Structure("Partner", LinkToListLinePartner(Form)));
	If Basis.Count() > 0 Then
		Partner = Basis[0]; // CatalogRef.Partners
		ShowValue(Undefined, Partner);
	EndIf;
	
EndProcedure

// Called from various forms of the Partners directory list when the selection for a partner segment is changed.
// Parameters:
//  Form                - ClientApplicationForm - the form in which the command is executed.
//  Item              - FormCommand     - completed form command.
//
Procedure PartnersFormOfSegmentSelectionListWhenChanging(Form, Item) Export
	
	If ValueIsFilled(Form.Segment) Then
		
		Form.Items.List.Representation = TableRepresentation.List;
		
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "SelectionBySegmentIsSet",
		                                                                   True);
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "FilterBySegment",
		                                                                   SegmentsOfCallServer.ValueList(Form.Segment).UnloadValues());
		
		SelectionListsClientServer.UpdateSelectionList(Form.Items.Segment.ChoiceList, Form.Segment, 7);
		Form.SegmentSelectionHistory.LoadValues(Form.Items.Segment.ChoiceList.UnloadValues());
		
	Else
		
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "SelectionBySegmentIsSet",
		                                                                   False);
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "FilterBySegment",
		                                                                   Undefined);
		Form.Items.List.Representation = TableRepresentation.HierarchicalList;
		
	EndIf;
	
EndProcedure

// Called from the "Before adding" event handler for various forms of the partner list.
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurs.
//  Item              - FormField                  - elements of the form where the event occurs.
//  Cancel                - Boolean                     - a sign of refusal to perform the copy.
//  Copy          - Boolean                     - indicates whether the item is copied.
//  Parent             - CatalogRef.Partners  - directory-parent of the partner.
//  Group               - Boolean                     - indicates that it is a group.
//  Basis            - Arbitrary               - base of the element being created.
//
Procedure PartnersSelectListFormListBeforeYouStartAdding(Form, Item, Cancel, Copy, Parent, Group, Basis = Undefined) Export
	
	If Copy Then
		If Not Form.SimplifiedInputAvailable Then
			Cancel = True;
			ClearMessages();
			MessageText = NStr("vi = 'Cấm sao chép %1.';
								|ru = 'Копирование %1 запрещено.';
								|en = '%1 copying is prohibited.'; fa = '%1 copying is prohibited.';
								|it = 'La copia %1 è proibita.';
								|pl = 'Kopiowanie %1 jest zabronione.';
								|tr = '%1''in kopyalanması yasaktır.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			            MessageText, 
			            ?(Form.UsePartnersAsCounterparties, NStr("vi = 'đối tác';
																|ru = 'контрагентов';
																|en = 'counterparties'; fa = 'counterparties';
																|it = 'controparti';
																|pl = 'kontrahentów';
																|tr = 'cari hesaplarının'"), NStr("vi = 'bạn hàng';
																								|ru = 'партнеров';
																								|en = 'partners'; fa = 'شرکای تجاری';
																								|it = 'partner';
																								|pl = 'partnerów';
																								|tr = 'iş ortaklarının'")));
			CommonClientServer.MessageToUser(NStr("vi = 'Cấm sao chép đối tác';
													|ru = 'Копирование партнеров запрещено.';
													|en = 'Partner copying is prohibited.'; fa = 'Partner copying is prohibited.';
													|it = 'Copiare i partner è proibito.';
													|pl = 'Kopiowanie partnerów jest zabronione.';
													|tr = 'İş ortaklarının kopyalanması yasaktır.'"));
		EndIf;
	Else
		Cancel = True;
		OpenForm("Catalog.Partners.Form.WizardOfNew",New Structure("ListFilterByPartnerType, Basis", Form.ListFilterByPartnerType, Basis), Form);
	EndIf;
	
EndProcedure

// Called from various forms of the "Partners" directory list when executing a command to create a new partner.
// Parameters:
//  Form   - ClientApplicationForm - the form in which the command is executed.
//  Command - FormCommand     - completed form command.
//
Procedure PartnersSelectListFormCreateNew(Form, Command) Export
	
	ParametersStructure1 = New Structure;
	StructureOfFillValue = New Structure;
	
	For Each FilterElement In TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") And FilterElement.ComparisonType = DataCompositionComparisonType.Equal And FilterElement.Use Then
			StructureOfFillValue.Insert(String(FilterElement.LeftValue), FilterElement.RightValue);
		EndIf;
	EndDo;
	
	If Form.Items.List.Representation <> TableRepresentation.List Then
		StructureOfFillValue.Insert("Parent", Form.Items.List.CurrentParent);
	EndIf;
	
	ParametersStructure1.Insert("FillingValues", StructureOfFillValue);
	ParametersStructure1.Insert("ListFilterByPartnerType", Form.ListFilterByPartnerType);
	
	If Not Form.UsePartnersAsCounterparties Then
		OpenForm("Catalog.Partners.Form.ItemForm", ParametersStructure1,Form);
	Else
		OpenForm("Catalog.Partners.Form.CounterpartyAttributesItemForm", ParametersStructure1,Form);
	EndIf;
	
EndProcedure 

#EndRegion

#Region GeneralProceduresAndFunctionsOfPartnerCatalogForms

// Called from the event handler "when changing" the element of various forms of the partner "Channel of primary interest".
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurs.
//  Item              - FormField                  - elements of the form where the event occurs.
//
Procedure PartnerElementFormChannelOfPrimaryInterestWhenModified(Form, Item) Export
	
	Form.SourceOfInitialRequest = Undefined;
	Form.Items.SourceOfInitialRequest.ReadOnly = Not ValueIsFilled(Form.ChannelOfInitialRequest);
	
EndProcedure

// Called from the event handler "when changing" the element of various forms of the partner "Name".
// Parameters:
//  Form                - ClientApplicationForm - The Form in which the event occurs contains:
//   * Object - CatalogObject.Partners - .
//  Item              - FormField     - elements of the form where the event occurs.
//
Procedure PartnerElementFormNameWhenChanged(Form, Item) Export
	
	If IsBlankString(Form.Object.DescriptionFull) Then
		Form.Object.DescriptionFull = Form.Object.Description;
	EndIf;
	
EndProcedure

// Called from the event handler "when changing" elements of various forms of the "relationship Type"partner.
// Parameters:
//  Form                - ClientApplicationForm - The Form in which the event occurs contains:
//    * Items - FormAllItems - Contains:
//      ** ServedBySalesRepresentatives - FormField - .
//      ** Carrier                            - FormField - .
//  Item              - FormField - elements of the form where the event occurs.
//
Procedure PartnerElementFormFlagPartnerAttributeWhenChanging(Form, Item) Export
	
	Form.Items.ServedBySalesRepresentatives.Enabled = Form.Object.Client;
	If Not Form.Object.Client Then
		Form.Object.ServedBySalesRepresentatives = False;
	EndIf;
	
	Form.Items.Carrier.Enabled = Form.Object.Vendor;
	If Not Form.Object.Vendor Then
		Form.Object.Carrier = False;
	EndIf;
	
EndProcedure

// Called from the event handler "Start selection" of the element of various forms of the partner "Comment".
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurs.
//  Item              - FormField     - the form element where the event occurs.
//  ChoiceData         - ValueList   - it can contain prepared data for selection.
//  StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure PartnerElementFormCommentsStartSelection(Form, Item, ChoiceData, StandardProcessing) Export
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		Form, 
		"Object.Comment");
	
EndProcedure

// Called from the event handler "when changing" the element of various forms of the partner "Business region".
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurs.
//  Item              - FormField                  - elements of the form where the event occurs.
//
Procedure PartnerFormOfBusinessRegionElementWhenChanged(Form, Item) Export
	
	If Form.Object.BusinessRegion <> Form.CurrentBusinessRegion Then
		
		If ValueIsFilled(Form.Object.BusinessRegion) Then
			MainManagerOfBusinessRegion = PartnersAndCounterpartiesServerCall.MainManagerOfBusinessRegion(Form.Object.BusinessRegion);
			If ValueIsFilled(MainManagerOfBusinessRegion) And MainManagerOfBusinessRegion <> Form.Object.MainManager Then
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối với khu vực kinh doanh đã chọn người quản lý chính là %1. Đặt làm người quản lý chính của bạn hàng?';
																							|ru = 'Для выбранного бизнес-региона основным менеджером является %1. Установить его основным менеджером партнера?';
																							|en = 'For selected business region %1 is the main manager. Set him or her as the main manager of the partner?'; fa = 'For selected business region %1 is the main manager. Set him or her as the main manager of the partner?';
																							|it = 'Per l''area commerciale selezionata il manager principale risulta essere %1. Impostarlo come manager principale del partner?';
																							|pl = 'Dla wybranego regionu biznesowego głównym menedżerem jest %1. Ustawić go jako głównego menedżera partnera?';
																							|tr = 'Seçilen iş bölgesi için ana yönetici %1 olmaktadır. Ana iş ortağı yöneticisi olarak yapılandırılsın mı?'"),MainManagerOfBusinessRegion);
				Result = Undefined;

				ShowQueryBox(New CallbackDescription("PartnerFormOfBusinessRegionElementWhenChangedCompletion", ThisObject, New Structure("MainManagerOfBusinessRegion, Form", MainManagerOfBusinessRegion, Form)), QueryText, QuestionDialogMode.YesNo);
                Return;
				
			EndIf;
		EndIf;
		
		Form.CurrentBusinessRegion = Form.Object.BusinessRegion;
		
	EndIf;
	
EndProcedure

// The completion handler of the select business in the region. Also sets the primary Manager of the business in the region.
// Parameters:
//  QuestionResult        - DialogReturnCode - the user's response to the question about the need to install the main Manager.
//  AdditionalParameters - Structure          - 
//                             In Osnovnoetrebovanie Spravochnike.Users - Manager of the business region.
//                             * Form - the form from which the selection form was called.
//
Procedure PartnerFormOfBusinessRegionElementWhenChangedCompletion(QuestionResult, AdditionalParameters) Export
	
	MainManagerOfBusinessRegion = AdditionalParameters.MainManagerOfBusinessRegion;
	Form = AdditionalParameters.Form;
	
	
	Result = QuestionResult;
	
	If Result = DialogReturnCode.Yes Then
		
		Form.Object.MainManager = MainManagerOfBusinessRegion;
		
	EndIf;
	
	Form.CurrentBusinessRegion = Form.Object.BusinessRegion;
	
EndProcedure

#EndRegion

#Region PropsHistory

// Called from various forms of the Contractors directory element when editing the TIN.
// Parameters:
//  Form                - ClientApplicationForm - The Form in which the Command is executed contains:
//    * Object - CatalogObject.Counterparties - 
//    * ContactInformationAdditionalAttributesDetails - ValueTable - Contains:
//    ** Kind - CatalogRef.ContactInformationKinds -
//  CompanyDetails_    - Structure        - details of the counterparty.
//
Procedure FillInAddressHistory(Form, CompanyDetails_) Export
	
	AddressHistory = GetPropsHistory(CompanyDetails_, "Address");
	
	If AddressHistory = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(AddressHistory) = Type("Array") 
		And AddressHistory.Count() > 0 Then
		AddressHistory[0].Date = Date(1,1,1);
	EndIf;

	If TypeOf(Form.Object.Ref) = Type("CatalogRef.Companies") Then
		ContactInformationTypeNameLegalEntityAddress = "LegalAddressOfCompany";
	Else
		ContactInformationTypeNameLegalEntityAddress = "LegalAddressOfCounterparty";
	EndIf;
	TypeOfContactInformationLegalEntityAddress = PredefinedValue("Catalog.ContactInformationKinds."+ContactInformationTypeNameLegalEntityAddress);
	
	Filter = New Structure("Kind", TypeOfContactInformationLegalEntityAddress);
	
	FoundRows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	
	AttributeName = "";
	ItemForPlacementName = "";
	StoreChangeHistory = True;
	For Each ContactInformationRow In FoundRows Do
		If Not ContactInformationRow.IsHistoricalContactInformation Then
			AttributeName = ContactInformationRow.AttributeName;
			ItemForPlacementName = ContactInformationRow.ItemForPlacementName;
			StoreChangeHistory = ContactInformationRow.StoreChangeHistory;
		EndIf;
		Form.ContactInformationAdditionalAttributesDetails.Delete(ContactInformationRow);
	EndDo;
	
	If Not StoreChangeHistory Then
		PartnersAndCounterpartiesServerCall.EnableChangeHistoryStorage(ContactInformationTypeNameLegalEntityAddress);
	EndIf;
	
	CurrentAddressIndex = AddressHistory.UBound();
	
	ParametersOfUpdate = New Structure;
	For Each ContactInformationRow In AddressHistory Do
		CurIndexOfContactInformation = AddressHistory.Find(ContactInformationRow);
		
		RowData = Form.ContactInformationAdditionalAttributesDetails.Add();
		RowData.Kind = TypeOfContactInformationLegalEntityAddress;
		RowData.Type = PredefinedValue("Enum.ContactInformationTypes.Address");
		RowData.Value = ContactInformationRow.ContactInformation;
		RowData.Presentation = ContactInformationRow.Presentation;
		RowData.Comment = ContactInformationRow.Comment;
		RowData.ItemForPlacementName = ItemForPlacementName;
		
		RowData.ValidFrom = ContactInformationRow.Date;
			
		If CurIndexOfContactInformation = CurrentAddressIndex Then
			RowData.AttributeName = AttributeName;
			RowData.IsHistoricalContactInformation = False;
			RowData.StoreChangeHistory = True;
		Else
			RowData.AttributeName = Undefined;
			RowData.IsHistoricalContactInformation = True;
			RowData.StoreChangeHistory = True;
		EndIf;
		
	EndDo;

EndProcedure

// Called from various forms of the Contractors directory element when editing the TIN.
// Parameters:
//  Form                - ClientApplicationForm - The Form in which the Command is executed contains:
//   * ContactInformationHistory - ValueTable - Contains:
//    ** Kind - CatalogRef.ContactInformationKinds -
//  CompanyDetails_    - Structure        - details of the counterparty.
//
Procedure FillInAddressHistoryInForm(Form, CompanyDetails_) Export
	
	Form.ContactInformationHistory.Clear();
	
	AddressHistory = GetPropsHistory(CompanyDetails_, "Address");
	If AddressHistory = Undefined Then
		Return;
	EndIf;
	
	If AddressHistory.Count() > 1 Then
		For Each Address In AddressHistory Do
			KIHistoryString = Form.ContactInformationHistory.Add();
			FillPropertyValues(KIHistoryString, Address);
			KIHistoryString.Kind           = PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty");
			KIHistoryString.Type           = PredefinedValue("Enum.ContactInformationTypes.Address");
			KIHistoryString.Date          = Address.Date;
			KIHistoryString.Value      = Address.ContactInformation;
		EndDo;
	EndIf;

EndProcedure

// Called from various forms of the Contractors directory element when editing the TIN.
// Parameters:
//  Object               - FormDataStructure - the details form.
//  CompanyDetails_    - Structure            - details of the counterparty.
//
Procedure FillInHistoryOfNames(Object, CompanyDetails_) Export
	
	ThisIsYurFace = StrLen(CompanyDetails_.TIN) = 10;
	
	Object.NameHistory.Clear();
	
	NameHistory = GetPropsHistory(CompanyDetails_,"Description");
	If NameHistory = Undefined Then
		Return;
	EndIf;
	
	If NameHistory.Count() > 0 Then
	    For i = 0 To NameHistory.UBound() Do
	        For j = 0 To NameHistory.UBound() - i - 1 Do
	            If NameHistory[j].Date > NameHistory[j + 1].Date Then
	                Replacement = NameHistory[j];
	                NameHistory[j] = NameHistory[j + 1];
	                NameHistory[j + 1] = Replacement;
	            EndIf;            
	        EndDo;        
	    EndDo;
	        
	    AttributeNameAbbreviatedName = Undefined;
		
		For Counter = 0 To NameHistory.Count() - 1 Do
			
			StringName = NameHistory[Counter];
			NameHistoryLine = Object.NameHistory.Add();
			
			If AttributeNameAbbreviatedName = Undefined Then
			
				If CommonClientServer.HasAttributeOrObjectProperty(NameHistoryLine, "NameAbbreviated") Then
					AttributeNameAbbreviatedName = "NameAbbreviated";
				ElsIf CommonClientServer.HasAttributeOrObjectProperty(NameHistoryLine, "AbbreviatedDescription") Then
					AttributeNameAbbreviatedName = "AbbreviatedDescription";
				Else
					Return;
				EndIf;
			
			EndIf;
			
			If Counter > 0 Then 
				NameHistoryLine.Period = StringName.Date;
			EndIf;
			FillPropertyValues(NameHistoryLine, StringName);
			NameHistoryLine[AttributeNameAbbreviatedName] = StringName.AbbreviatedDescription;
			If Not ThisIsYurFace Then
				
				NameHistoryLine[AttributeNameAbbreviatedName] = StrTemplate(NStr("vi = 'DNTN %1';
																				|ru = 'ИП %1';
																				|en = 'IE %1'; fa = 'IE %1';
																				|it = 'Imprenditore Individuale %1';
																				|pl = 'PI %1';
																				|tr = 'BG %1'"), StringName.AbbreviatedDescription);
				PartnersAndCounterpartiesLocalizationClient.AddNameHistoryData(NameHistoryLine, AttributeNameAbbreviatedName, CompanyDetails_.AbbreviatedDescription);
				
			EndIf;
		EndDo;
	EndIf;

EndProcedure

Function GetPropsHistory(CompanyDetails_, AttributeName) Export
	
	PropsHistory = Undefined;
	Result         = Undefined;
	
	If Not (CompanyDetails_.Property("PropsHistory", PropsHistory) 
		And TypeOf(PropsHistory) = Type("Structure")
		And PropsHistory.Property(AttributeName, Result)
		And TypeOf(Result) = Type("Array")) Then
		
		Return Undefined;
	EndIf;
	
	Return Result
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region GeneralProceduresAndFunctionsOfListAndCatalogSelectionForms

// Saves the settings of the navigation panel of the Partners directory list form.
// 
// Parameters:
//   Form - ClientApplicationForm - THE Form for which conditional registration is set contains:
//   * Items - FormAllItems - Contains:
//    ** SearchString  - FormField - 
//    ** BusinessRegions           - FormTable -
//    ** PartnerAccessGroups  - FormTable -
//    ** Properties                - FormTable - 
//    ** Managers               - FormTable - 
//    ** Categories               - FormTable - 
//
Procedure SaveNavigationBarSettings(Form)

	If Form.Items.PagesFilterType.CurrentPage = Form.Items.CategoriesPage Then
		PanelKind = "Categories";
		CurrentRow = Form.Items.Categories.CurrentRow;
		If CurrentRow <> Undefined Then
			CurrentData = Form.Categories.FindByID(CurrentRow);
			If CurrentData <> Undefined Then
				 CurrentValue = CurrentData.Value;
			EndIf;
		EndIf;
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageBusinessRegions Then
		PanelKind = "BusinessRegions";
		CurrentValue = Form.Items.BusinessRegions.CurrentRow;
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageAccessGroups Then
		PanelKind = "AccessGroups";
		CurrentValue = Form.Items.PartnerAccessGroups.CurrentRow;
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers Then
		PanelKind = "Manager";
		CurrentValue = Form.Items.Managers.CurrentRow;
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PropertiesPage Then
		PanelKind = Form.CurrentPropertyOfNavigationPanel;
		CurrentRow = Form.Items.Properties.CurrentRow;
		If CurrentRow <> Undefined Then
			CurrentData = Form.Properties.FindByID(CurrentRow);
			If CurrentData <> Undefined Then
				 CurrentValue = CurrentData.Value;
			EndIf;
		EndIf;
	Else
		Return;
	EndIf;
	
	FoundRows = Form.NavigationPanelSettings.FindRows(New Structure("PanelKind",PanelKind));
	If FoundRows.Count() = 0 Then
		SettingsString = Form.NavigationPanelSettings.Add();
		SettingsString.PanelKind = PanelKind;
	Else
		SettingsString = FoundRows[0];
	EndIf;
	
	SettingsString.CurrentValue = CurrentValue;

EndProcedure

Function LinkToListLinePartner(Form)
	
	CurrentData = Form.Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ?(Form.FormName = "Catalog.Counterparties.Form.ChoiceFormOnlyPartnersAreUsed",
	          CurrentData.Partner,
	          CurrentData["Ref"]);
	
EndFunction

#EndRegion

#EndRegion
