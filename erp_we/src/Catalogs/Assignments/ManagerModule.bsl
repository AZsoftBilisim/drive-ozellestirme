#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region SelectingAssignmentsInDocuments

// Returns the structure of parameters for generating a request for available assignments
//
//	Returns:
//		Structure - structure with fields:
//			* ChoiceMode - String - destination selection mode.
//			* OperationKind - EnumRef.OperationKindsOfGoodsPlacementPicking - type of warehouse operation
//			* TakeIntoAccountAlreadySelected - Boolean - need to account for changes in the balance due to previously selected assignments
//			* ForSeveralProducts - Boolean - True if for multiple products
//			* SortByDateOfAppointmentOrder -Boolean - need to order by order date 
//			* Source - DocumentRef - link to the document where the assignment is selected
//
Function ParametersForCreatingRequestForAvailableAssignments() Export
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ChoiceMode");
	ParametersStructure.Insert("OperationKind");	
	ParametersStructure.Insert("TakeIntoAccountAlreadySelected", False);
	ParametersStructure.Insert("ForSeveralProducts", False);
	ParametersStructure.Insert("SortByDateOfAppointmentOrder", False);
	ParametersStructure.Insert("Source");

	Return ParametersStructure;
	
EndFunction

// Template for setting up the appointment selection form.
// To display columns, for example, "Need" or "Available", you need
// to connect the corresponding column description using the Add Column description method.
//
// Example of a function that embeds a form for selecting assignments in a document:
// 
// 	Function for a layout form for selecting assignments() Export
// 		Mock-up forms = Catalogs.Appointments.Layout formselection of assignments();
// 		Template assignments = Catalogs.Appointments.Add Template values (Layout forms);
// 		
// 		Description of columns = Catalogs.Appointments.Add a description of the columns (Form layout, "Securing orders", Truth, "Object.Products.Appointment");
// 		Description of columns.Speakers.Find the meaning ("in cash").Tag = True;
// 		Description of columns.PutiKDannom.Product = "Object.Products.Products";
// 		Description of columns.PutiKDannom.Characteristic = "Object.Products.Characteristics";
// 		Description of columns.PutiKDannom.Warehouse = "Object.Sender";
// 		
// 		Returning the layout form;
// 	The end of the function
// 
// Returns:
//   Structure:
//   	* ColumnDescriptions  - Array - structures defined by the column layout method.
//   	* Title        - String - overridable title of the assignment selection form.
//   	* DestinationPattern - Array - selection structures by field of the Destination directory element,
//   							multiple templates are applied if there are multiple paths to the Destination field.
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = New Structure();
	FormTemplate.Insert("ColumnDescriptions", New Array);
	FormTemplate.Insert("Title");
	
	FormTemplate.Insert("AssignmentTemplates", New Array);
	
	Return FormTemplate;
	
EndFunction

// Returns a structure that imposes conditions on the values
// of the details of elements in the Destination directory.
//
// Parameters:
//  FormTemplate - Structure - defined in the maketform method for selecting Assignments. The return value
//  						 of the current function will be placed in the "template Values" key of the form layout.
//  PathToTheDestinationField - String - the path to the destination field.
// Returns:
//   Structure - structure with fields:
//   	* RecordsInWarehouseRegisters - Boolean - the value of the Catalog Attribute of the same name that you are looking for
//   	* LineOfBusiness      - CatalogRef.LinesOfBusiness - the value of the Catalog Attribute of the same name that you are looking for
//   	* OrderDocument                        - DocumentRef - the value of the Catalog Attribute of the same name that you are looking for
//   	* Partner                      - CatalogRef.Partners - the value of the Catalog Attribute of the same name that you are looking for
//   	* Contract                      - CatalogRef.CounterpartyContracts - the value of the Catalog Attribute of the same name that you are looking for
//   	* Ref                       - Array of CatalogRef.Assignments - the value of the Catalog Attribute of the same name that you are looking for
//   	* AssignmentTypes               - Array of EnumRef.AssignmentTypes - List of appointment types that will be displayed
//   	* TermsOfUse_         - String - An expression that determines whether to use the specified selections. It can be specified as a boolean,
//   	                                          for example, "TRUE", or "FALSE", or as an expression, for example
//   	                                          , "Object.Business Operation = VALUE(Enumeration.Economic operations.Productionizdavalchesky raw materials)
//   	                                          And the Object.sender Catalog link.Warehouses."
//   	* PathToTheDestinationField          - String - The field of the Assignment form to which the specified conditions apply. If not specified, applies to all fields.
//   	* VisibleSelectionsOnForm         - Structure - Description of the selections to display on the form in the form of a checkbox
//   	                                             The key is the Selection name, the value is the Title on the form.
//   	* ExcludeRefAssignment    - Boolean - True if you need to exclude the assignment of a link from the form object from the selection form
Function AddAppointmentTemplate(FormTemplate, PathToTheDestinationField = "") Export
	
	DestinationPattern = New Structure();
	DestinationPattern.Insert("RecordsInWarehouseRegisters");
	DestinationPattern.Insert("LineOfBusiness");
	DestinationPattern.Insert("OrderDocument");
	DestinationPattern.Insert("Partner");
	DestinationPattern.Insert("Contract");
	DestinationPattern.Insert("Ref"); // for selection by an array of destination links
	DestinationPattern.Insert("ExcludeRefAssignment", True); 
	
	DestinationPattern.Insert("AssignmentTypes", New Array);
	For Each Value In Enums.AssignmentTypes Do
		DestinationPattern.AssignmentTypes.Add(Value);
	EndDo;
	
	DestinationPattern.Insert("TermsOfUse_", "TRUE");
	DestinationPattern.Insert("PathToTheDestinationField",  PathToTheDestinationField);
	DestinationPattern.Insert("VisibleSelectionsOnForm", New Structure);
	
	FormTemplate.AssignmentTemplates.Add(DestinationPattern);
	
	Return DestinationPattern;
	
EndFunction

// Returns a description of the columns that can be displayed in
// the destination selection form. The returned structure is defined
// in the column layout method.
//
// Parameters:
//  FormTemplate			 - Structure - defined in the maketform method for selecting Assignments. The return value
//										of the current function will be placed in the column Descriptionkey of the form layout.
//  DataSource		 - String - flag that defines the rules for filling in the column description layout.
//  AddStorno		 - Boolean - the defining characteristic to include in the query text reversal by the Registrar.
//  PathToTheDestinationField	 - String - path to the Destination field, such as " Object.Goods.Purpose".
//  Prefix				 - String - if two identical data sources are used at the same time, you must fill
//									in this field, i.e. set the return value to a unique identifier.
// 
// Returns:
//   See ColumnDescriptionTemplate
//
Function AddColumnDescription_(FormTemplate, DataSource, AddStorno, PathToTheDestinationField, Prefix = "") Export
	
	ReturnValue = Undefined;
	
	If DataSource = "OrderFulfillment" Then
		
		Prefix = ?(IsBlankString(Prefix), "OrderFulfillment", Prefix);
		
		// Forming a list of columns that can be displayed in the list of assignments
		PresentationParameter = "%" + Prefix + "_Warehouse%";
		PresentationNeed = StrTemplate(NStr("vi = 'Nhu cầu tại kho ""%1""';
											|ru = 'Потребность на складе ""%1""';
											|en = 'Demand in warehouse ""%1""'; fa = 'Demand in warehouse ""%1""';
											|it = 'Necessità nel magazzino ""%1""';
											|pl = 'Zapotrzebowanie w magazynie ""%1""';
											|tr = 'Ambardaki gereksinim ""%1""'"), PresentationParameter);
		PresentationInStock = StrTemplate(NStr("vi = 'Có sẵn để giao hàng tại kho ""%1""';
												|ru = 'Доступно для отгрузки на складе ""%1""';
												|en = 'Available for shipment at the ""%1"" warehouse'; fa = 'Available for shipment at the ""%1"" warehouse';
												|it = 'Available for shipment at the ""%1"" warehouse';
												|pl = 'Available for shipment at the ""%1"" warehouse';
												|tr = 'Ambarda ""%1"" sevkiyata hazır'"), PresentationParameter);
		PresentationArchivalRemains = StrTemplate(NStr("vi = 'Đã đặt trong kho ""%1""';
														|ru = 'Заказано на складе ""%1""';
														|en = 'Ordered at warehouse ""%1""'; fa = 'Ordered at warehouse ""%1""';
														|it = 'Ordinato nel magazzino ""%1""';
														|pl = 'Zamówiono w magazynie ""%1""';
														|tr = 'Ambarda sipariş edilen ""%1""'"), PresentationParameter);
		PresentationAvailableForReservation = StrTemplate(NStr("vi = 'Trong kho tại kho ""%1""';
																|ru = 'В наличии на складе ""%1""';
																|en = 'In stock in the ""%1"" warehouse'; fa = 'In stock in the ""%1"" warehouse';
																|it = 'Disponibile nel magazzino ""%1""';
																|pl = 'Jest w magazynie ""%1""';
																|tr = 'Ambardaki bakiye ""%1""'"), PresentationParameter);
		
		Columns = New ValueList();
		Columns.Add("InStock", PresentationInStock, False);
		Columns.Add("AvailableForReservation", PresentationAvailableForReservation, False);
		Columns.Add("Demand", PresentationNeed, False);
		Columns.Add("Archive_", PresentationArchivalRemains, False);
		
		ReturnValue = AddDescriptionOfYourOrders(FormTemplate, AddStorno, Prefix, Columns, True);
		
	ElsIf DataSource = "FulfillOrdersWithWorks" Then
		
		Prefix = ?(IsBlankString(Prefix), "FulfillOrdersWithWorks", Prefix);
		
		// Forming a list of columns that can be displayed in the list of assignments
		PresentationParameter = "%" + Prefix + "_Department%";
		PresentationNeed = StrTemplate(NStr("vi = 'Nhu cầu tại bộ phận ""%1""';
											|ru = 'Потребность в подразделении ""%1""';
											|en = 'Demand in the ""%1"" business unit'; fa = 'Demand in the ""%1"" business unit';
											|it = 'Necessità nel reparto ""%1""';
											|pl = 'Zapotrzebowanie w dziale ""%1""';
											|tr = 'Departmandaki gereksinim ""%1""'"), PresentationParameter);
		PresentationInStock = StrTemplate(NStr("vi = 'Có sẵn để giao hàng tại bộ phận ""%1""';
												|ru = 'Доступно для отгрузки в подразделении ""%1""';
												|en = 'Available for shipment at the ""%1"" business unit'; fa = 'Available for shipment at the ""%1"" business unit';
												|it = 'Available for shipment at the ""%1"" business unit';
												|pl = 'Available for shipment at the ""%1"" business unit';
												|tr = 'Departmanda ""%1"" sevkiyata hazır'"), PresentationParameter);
		PresentationArchivalRemains = StrTemplate(NStr("vi = 'Đã đặt tại bộ phận ""%1""';
														|ru = 'Заказано в подразделении ""%1""';
														|en = 'Ordered in the ""%1"" business unit'; fa = 'Ordered in the ""%1"" business unit';
														|it = 'Ordered in the ""%1"" business unit';
														|pl = 'Ordered in the ""%1"" business unit';
														|tr = 'Departmanda ""%1"" sipariş edilen'"), PresentationParameter);
		PresentationAvailableForReservation = StrTemplate(NStr("vi = 'Có sẵn tại bộ phận ""%1""';
																|ru = 'В наличии в подразделении ""%1""';
																|en = 'Available at the ""%1"" business unit'; fa = 'Available at the ""%1"" business unit';
																|it = 'Disponibile nel reparto ""%1""';
																|pl = 'Dostępny towar w dziale ""%1""';
																|tr = '""%1"" departmanında mevcuttur'"), PresentationParameter);
		
		Columns = New ValueList();
		Columns.Add("InStock", PresentationInStock, False);
		Columns.Add("AvailableForReservation", PresentationAvailableForReservation, False);
		Columns.Add("Demand", PresentationNeed, False);
		Columns.Add("Archive_", PresentationArchivalRemains, False);
		
		ReturnValue = AddDescriptionOfYourOrders(FormTemplate, AddStorno, Prefix, Columns, True);
		
	ElsIf DataSource = "SecuringOrdersAllWarehouses" Then
		
		Prefix = ?(IsBlankString(Prefix), "SecuringOrdersAllWarehouses", Prefix);
		
		Columns = New ValueList();
		Columns.Add("InStock", NStr("vi = 'Có sẵn để giao hàng tại tất cả các kho';
									|ru = 'Доступно для отгрузки на всех складах';
									|en = 'Available for shipment at all warehouses'; fa = 'Available for shipment at all warehouses';
									|it = 'Available for shipment at all warehouses';
									|pl = 'Available for shipment at all warehouses';
									|tr = 'Tüm ambarlarda sevkiyata hazır'"), False);
		Columns.Add("AvailableForReservation", NStr("vi = 'Trong kho tại tất cả các kho';
													|ru = 'В наличии на всех складах';
													|en = 'In stock in all warehouses'; fa = 'In stock in all warehouses';
													|it = 'Disponibile in tutti i magazzini';
													|pl = 'Jest we wszystkich magazynach';
													|tr = 'Tüm depolarda mevcuttur'"), False);
		Columns.Add("Demand", NStr("vi = 'Nhu cầu tại tất cả các kho';
									|ru = 'Потребность на всех складах';
									|en = 'Demand in all warehouses'; fa = 'Demand in all warehouses';
									|it = 'Necessità in tutti i magazzini';
									|pl = 'Zapotrzebowanie we wszystkich magazynach';
									|tr = 'Tüm ambarlardaki gereksinim'"), False);
		Columns.Add("Archive_", NStr("vi = 'Đã đặt trong tất cả kho';
									|ru = 'Заказано на всех складах';
									|en = 'Ordered at all warehouses'; fa = 'Ordered at all warehouses';
									|it = 'Ordinato in tutti i magazzini';
									|pl = 'Zamówiono we wszystkich magazynach';
									|tr = 'Tüm ambarlarda sipariş edilen'"), False);
		
		Prefix = ?(IsBlankString(Prefix), "SecuringOrdersAllWarehouses", Prefix);
		ReturnValue = AddDescriptionOfYourOrders(FormTemplate, AddStorno, Prefix, Columns, False);
		
		ReturnValue.Cancel = Not GetFunctionalOption("UseSeveralWarehouses");
		

	ElsIf DataSource = "MaterialsAndWorksInProduction" Then
		
		ReturnValue = AddDescriptionOfMaterialsAndWorkInProduction(FormTemplate, AddStorno, Prefix);
	ElsIf DataSource = "GoodsTransferredToCustodians" Then
		
		ReturnValue = AddDescriptionOfProductsSentToKeepers(FormTemplate, AddStorno, Prefix);
		
	ElsIf DataSource = "AllAssignments" Then
		
		ReturnValue = AddDescriptionOfAllDestinations(FormTemplate);
		
	ElsIf DataSource = "ImplementationData" Then
		
		ReturnValue = AddDescriptionImplementationData(FormTemplate, Prefix);
		
	Else
		ErrorText = NStr("vi = 'Nguồn dữ liệu ""%1"" không được cung cấp.';
						|ru = 'Источник данных ""%1"" не предусмотрен.';
						|en = 'The ""%1"" data source is not provided.'; fa = 'The ""%1"" data source is not provided.';
						|it = 'La sorgente dei dati ""%1"" non è prevista.';
						|pl = 'Źródło danych ""%1"" nie jest przewidziane.';
						|tr = '""%1"" veri kaynağı öngörülmedi.'");
		ErrorText = StrTemplate(ErrorText, DataSource);
		Raise ErrorText;
		
	EndIf;
	
	ReturnValue.PathToTheDestinationField = PathToTheDestinationField;
	
	Return ReturnValue;
	
EndFunction

// Initializes selections for selecting assignments on The Form.
//
// Parameters:
//  ObjectForm - ClientApplicationForm - The APPLICATION Form For which you want To configure the Destination item.
//  PathsToDestinationField - String - paths to the assignment fields that are relevant for this Form of the object.
//
Procedure DocumentFormWhenCreatedOnServer(ObjectForm, PathsToDestinationField = Undefined) Export
	
	ObjectName = Left(ObjectForm.FormName, StrFind(ObjectForm.FormName,".Form") - 1);
	ObjectManager = Common.ObjectManagerByFullName(ObjectName);
	
	AssignmentSelectionFormTemplate = ObjectManager.AssignmentSelectionFormTemplate();
	
	TemplateLinks = New Structure();
	
	For Each DestinationPattern In AssignmentSelectionFormTemplate.AssignmentTemplates Do
		
		If PathsToDestinationField <> Undefined
				And DestinationPattern.PathToTheDestinationField <> ""
				And StrFind(PathsToDestinationField, DestinationPattern.PathToTheDestinationField) = 0 Then
			Continue;
		EndIf;
		
		DestinationFieldPathKey = StrReplace(DestinationPattern.PathToTheDestinationField, ".", "");
		DestinationFieldPathKey = ?(IsBlankString(DestinationFieldPathKey), "EmptyKey", DestinationFieldPathKey);
		
		If Not TemplateLinks.Property(DestinationFieldPathKey) Then
			TemplateLinks.Insert(DestinationFieldPathKey, New Array());
		EndIf;
		
		FormTable = FormTable(ObjectForm.Items, DestinationPattern.PathToTheDestinationField);
		
		For Each FilterField In DestinationPattern Do
			If FilterField.Key = "PathToTheDestinationField"
				Or FilterField.Key = "ExcludeRefAssignment"
				Or FilterField.Key = "VisibleSelectionsOnForm" Then
				Continue;
			EndIf;
			If ValueIsFilled(FilterField.Value)
				And (StrFind(FilterField.Value, "Object.") <> 0
					Or StrFind(FilterField.Value, "&") <> 0) Then
				
				DataPaths = DataPathsTermsOfUse("", FilterField.Value,
					DestinationPattern.PathToTheDestinationField, FormTable, Undefined);
				For Each Path In DataPaths Do
					LinkFound = False;
					For Each Current_Connection In TemplateLinks[DestinationFieldPathKey] Do
						If Current_Connection.Name = Path.Key Then
							LinkFound = True;
							Break;
						EndIf;
					EndDo;
					If Not LinkFound Then
						Link = New ChoiceParameterLink(Path.Key, Path.Value,
							LinkedValueChangeMode.DontChange);
						TemplateLinks[DestinationFieldPathKey].Add(Link);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
	EndDo;
	
	ArrayOfPathsToDestinationField = New Array();
	For Each DescriptionOfColumns In AssignmentSelectionFormTemplate.ColumnDescriptions Do
		ArrayOfPathsToDestinationField.Add(DescriptionOfColumns.PathToTheDestinationField);
	EndDo;
	ArrayOfPathsToDestinationField = CommonClientServer.CollapseArray(ArrayOfPathsToDestinationField);
	
	For Each PathToTheDestinationField In ArrayOfPathsToDestinationField Do
		
		If PathsToDestinationField <> Undefined
				And StrFind(PathsToDestinationField, PathToTheDestinationField) = 0 Then
			Continue;
		EndIf;
		
		ArrayOfLinks = New Array();
		
		PathToTabularSection = Undefined;
		FormItemName = Undefined;
		FormTableName = Undefined;
		For Each DescriptionOfColumns In AssignmentSelectionFormTemplate.ColumnDescriptions Do
			If DescriptionOfColumns.PathToTheDestinationField <> PathToTheDestinationField Then
				Continue;
			EndIf;
			
			FormItemName = DescriptionOfColumns.FormItemName;
			FormTableName = DescriptionOfColumns.FormTableName;
			If DescriptionOfColumns.PathToTabularSection <> Undefined Then
				PathToTabularSection = DescriptionOfColumns.PathToTabularSection;
				Break;
			EndIf;
		EndDo;
		
		If FormItemName <> Undefined Then
			DestinationField_ = ObjectForm.Items[FormItemName];
		Else
			DestinationField_ = DestinationField_(ObjectForm.Items, PathToTheDestinationField);
		EndIf;
		If FormTableName <> Undefined Then
			FormTable = ObjectForm.Items[FormTableName];
		Else
			FormTable = FormTable(ObjectForm.Items, PathToTheDestinationField);
		EndIf;
		
		For Each DescriptionOfColumns In AssignmentSelectionFormTemplate.ColumnDescriptions Do
			
			If DescriptionOfColumns.PathToTheDestinationField <> PathToTheDestinationField Then
				Continue;
			EndIf;
			
			For Each DataPath In DescriptionOfColumns.DataPaths Do
				
				If Not ValueIsFilled(DataPath.Value) Then
					Continue;
				EndIf;
				
				RefinedDataPath = GenerateDataPath(DataPath.Value, PathToTheDestinationField, FormTable, PathToTabularSection);
				
				Name = DescriptionOfColumns.Prefix + "_" + DataPath.Key;
				
				RelationshipOfSelectionParameters = New ChoiceParameterLink(Name, RefinedDataPath, LinkedValueChangeMode.DontChange);
				
				ArrayOfLinks.Add(RelationshipOfSelectionParameters);
				
			EndDo;
			If ValueIsFilled(DescriptionOfColumns.TermsOfUse_) Then
				
				DataPathsTermsOfUse = DataPathsTermsOfUse(
					DescriptionOfColumns.Prefix,
					DescriptionOfColumns.TermsOfUse_,
					PathToTheDestinationField,
					FormTable,
					PathToTabularSection);
				
				For Each DataPath In DataPathsTermsOfUse Do
					
					If ArrayOfLinks.Find(DataPath.Key) = Undefined Then
						
						RelationshipOfSelectionParameters = New ChoiceParameterLink(DataPath.Key, DataPath.Value, LinkedValueChangeMode.DontChange);
						ArrayOfLinks.Add(RelationshipOfSelectionParameters);
						
					EndIf;
					
				EndDo;
				
			EndIf;
		EndDo;
		
		If ObjectForm.Object.Property("Ref") Then
			LinkBySource = New ChoiceParameterLink("Source", "Object.Ref", LinkedValueChangeMode.DontChange);
			ArrayOfLinks.Add(LinkBySource);
		EndIf;
		
		DestinationFieldPathKey = StrReplace(PathToTheDestinationField, ".", "");
		If TemplateLinks.Property(DestinationFieldPathKey) Then
			CommonClientServer.SupplementArray(ArrayOfLinks, TemplateLinks[DestinationFieldPathKey]);
		EndIf;
		If TemplateLinks.Property("EmptyKey") Then
			CommonClientServer.SupplementArray(ArrayOfLinks, TemplateLinks["EmptyKey"]);
		EndIf;
		
		ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
		
		ChoiceParameter = New ChoiceParameter("PathToTheDestinationField", PathToTheDestinationField);
		ChoiceParameters = New Array();
		ChoiceParameters.Add(ChoiceParameter);
		
		ChoiceParameter = New ChoiceParameter("ObjectName", ObjectName);
		ChoiceParameters.Add(ChoiceParameter);
		
		DestinationField_.ChoiceParameterLinks = ChoiceParameterLinks;
		DestinationField_.ChoiceParameters = New FixedArray(ChoiceParameters);
		DestinationField_.ChoiceForm = "Catalog.Assignments.Form.AssignmentChoiceForm";
		
	EndDo;
	
EndProcedure

// To get a Presentation of an appointment that has not yet been created in the user's language.
// Parameters:
//  DestinationPattern - See NewSubmenuTemplate
//  DocumentAttributes - Structure - structure with fields:
//   * Number - String - document number
//   * Date - Date - Document date
//   * Recipient - CatalogRef.Partners - Recipient
//  Returns:
//   String - Performance.
Function PresentationOfDestinationByTemplate(DestinationPattern, DocumentAttributes) Export
	
	Presentation = PresentationOfDestinationForRecordingInInformationBase(
		DestinationPattern,
		DocumentAttributes);
		
	IsMainLanguage = TMCommonUseCached.IsMainLanguage();
	If Not IsMainLanguage Then
		
		TypePresentation = AssignmentsClientServer.DestinationTypePresentation(DestinationPattern, "");
		If TypePresentation <> Undefined Then
			
			OpeningBracketPosition = StrFind(Presentation, "(", SearchDirection.FromEnd);
			CroppedView = Left(Presentation, OpeningBracketPosition);
			Presentation = CroppedView + TypePresentation + ")";
			
		EndIf;
		
	EndIf;
	Return Presentation;
	
EndFunction

#EndRegion

#Region InterfaceForAccessingAppointmentDetails

// Returns the activity directions of the passed assignments
// Parameters:
//  Assignments - Array - array of assignments.
// Returns:
//  Map - Key - assignment,
//                 Value - the direction of activity.
//
Function AreasOfActivityOfAppointments(Assignments) Export
	
	Query = New Query(
		"SELECT
		|	Assignments.Ref                  AS Ref,
		|	Assignments.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.Assignments AS Assignments
		|WHERE
		|	Assignments.Ref IN (&Assignments)");
	Query.SetParameter("Assignments", Assignments);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Result = New Map;
	While Selection.Next() Do
		Result.Insert(Selection.Ref, Selection.LineOfBusiness);
	EndDo;
	
	Return Result;
	
EndFunction

// Fills in the assignment attributes based on their service details.
//
// Parameters:
//   Assignments - Array - array of assignments.
//
// Returns:
//   Map - where the Key is the destination and the Value is a structure with properties:
//     * ThisIsAppointmentOfGiver - Boolean - indicates that the assignment is a giver (2.4).
//     * ThisIsAppointmentOfGiver2_5 - Boolean - a sign that the appointment is a giver (2.5).
//     * ThisIsPurposeOfDirectionOfActivity - Boolean - indicates that the destination is
//               the destination of receipt of goods in the direction of activity.
//     * TheseAreGiverProducts - Boolean
//     * ItIsTakenIntoAccountInWarehouseSubsystem - Boolean
//
Function AssignmentProperties(Assignments) Export
	
	Result = New Map;
	
	If Not ValueIsFilled(Assignments) Then
		Return Result;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	Table.Ref AS Ref,
		|	Table.LineOfBusiness AS LineOfBusiness,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.Partner AS Partner,
		|	Table.Contract AS Contract,
		|	Table.AssignmentType AS AssignmentType,
		|	Table.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters
		|FROM
		|	Catalog.Assignments AS Table
		|WHERE
		|	Table.Ref IN(&References)");
	Query.SetParameter("References", Assignments);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Value = New Structure();
		Value.Insert("ThisIsAppointmentOfGiver2_5", False);
		Value.Insert("ThisIsPurposeOfDirectionOfActivity", False);
		Value.Insert("TheseAreGiverProducts", False);
		Value.Insert("ItIsTakenIntoAccountInWarehouseSubsystem", Selection.RecordsInWarehouseRegisters);
		Value.Insert("LineOfBusiness", Selection.LineOfBusiness);
		Value.Insert("Contract", Selection.Contract);
		Value.Insert("AssignmentType", Selection.AssignmentType);
		
		If Selection.AssignmentType = Enums.AssignmentTypes.Giveaway2_5 Then
			Value.ThisIsAppointmentOfGiver2_5 = True;
		ElsIf Selection.AssignmentType = Enums.AssignmentTypes.ProvidedMaterialsForStage22 Then
			Value.ThisIsAppointmentOfGiver2_5 = True;
		EndIf;
		

		If Not Selection.LineOfBusiness.IsEmpty() And Selection.Partner.IsEmpty() And Not ValueIsFilled(Selection.OrderDocument) Then
			Value.ThisIsPurposeOfDirectionOfActivity = True;
		EndIf;
		
		Result.Insert(Selection.Ref, Value);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Called when replacing duplicates in the Attributes of elements.
//
// Parameters:
//  ReplacementPairs - Map - contains the original and duplicate value pairs.
//  UnprocessedOriginalsValues - Array of Structure:
//    * ValueToReplace - AnyRef - the original value of the object being replaced.
//    * UsedLinks - See Common.SubordinateObjectsLinksByTypes
//    * KeyAttributesValue - Structure - Key - name of the item, value-value of the item.
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedOriginalsValues) Export

	For Each UnprocessedDuplicate In UnprocessedOriginalsValues Do
		
		ParametersOfKey = New Structure;
		For Each KeyAttribute In UnprocessedDuplicate.KeyAttributesValue Do
			ValueOfOriginal = ReplacementPairs.Get(KeyAttribute.Value);
			ParametersOfKey.Insert(KeyAttribute.Key, ?(ValueOfOriginal = Undefined, KeyAttribute.Value, ValueOfOriginal));
		EndDo;
		
		// @skip-check query-in-loop - otherwise it is impossible to understand whether such a key exists or not
		ReplacementPairs.Insert(UnprocessedDuplicate.ValueToReplace, CreateByKey(ParametersOfKey));
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	
	Fields.Add("Description");
	Fields.Add("OrderDocument");
	Fields.Add("Contract");
	Fields.Add("Partner");
	Fields.Add("LineOfBusiness");
	Fields.Add("AssignmentType");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	Presentation = Data.Description;
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
	IsMainLanguage = False;
	#If Client Then
		IsMainLanguage = TMCommonUseClientCached.IsMainLanguage();
		DefaultLanguageCode = CommonClient.DefaultLanguageCode();
		
	#Else
		IsMainLanguage = TMCommonUseCached.IsMainLanguage();
		DefaultLanguageCode = Common.DefaultLanguageCode();
	#EndIf
	
	If Not IsMainLanguage Then
		
		PresentationOfTypeInMainLanguage = AssignmentsClientServer.DestinationTypePresentation(Data, DefaultLanguageCode);
		PresentationOfTypeInMainLanguage = "(" + PresentationOfTypeInMainLanguage + ")";
		
		TypePresentation = AssignmentsClientServer.DestinationTypePresentation(Data, "");
		TypePresentation = "(" + TypePresentation + ")";
		If TypePresentation <> Undefined Then
			Presentation = StrReplace(Presentation, PresentationOfTypeInMainLanguage, TypePresentation);
		EndIf;
		
	EndIf;
	
	#EndIf
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("Source")
		And Parameters.Property("PathToTheDestinationField") Then
		
		AssignmentsServerCall.AssignmentsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
		
	ElsIf Parameters.Property("LineOfBusiness")
		And ValueIsFilled(Parameters.LineOfBusiness) Then
		
		Parameters.Filter.Insert("LineOfBusiness", Parameters.LineOfBusiness);
		
	Else
		
		AssignmentsServerCall.AddPartnerExclusionSelection(Parameters.Filter);
		
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		
		If Parameters.Property("OpenLinkedObject") 
			And Parameters.OpenLinkedObject Then
			
			Purpose = Parameters.Key;
			
			Query = New Query();
			Query.Text = 
			"SELECT 
			|	Purpose.OrderDocument AS OrderDocument,
			|	Purpose.LineOfBusiness AS LineOfBusiness
			|FROM
			|	Catalog.Assignments AS Purpose
			|WHERE
			|	Purpose.Ref = &Purpose";
			Query.SetParameter("Purpose", Purpose);
			
			DetailsOfAppointment = Query.Execute().Select();
			DetailsOfAppointment.Next();
			
			If ValueIsFilled(DetailsOfAppointment.OrderDocument) Then
				
				StandardProcessing = False;
				
				Parameters.Key = DetailsOfAppointment.OrderDocument;
				OrderMetadata = DetailsOfAppointment.OrderDocument.Metadata();
				SelectedForm = OrderMetadata.DefaultObjectForm;
				
			ElsIf ValueIsFilled(DetailsOfAppointment.LineOfBusiness) Then
				
				StandardProcessing = False;
				
				Parameters.Key = DetailsOfAppointment.LineOfBusiness;
				SelectedForm = Metadata.Catalogs.LinesOfBusiness.DefaultObjectForm;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region SelectingAssignmentsInDocuments

#Region Compatibility

// Returns the text of the request for available assignments based on cell balances
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignmentsBasedOnBalancesInCell(RequestFormationParameters) Export
	
	QueryText =
	"SELECT
	|	RegisterDataInCells.Products AS Products,
	|	RegisterDataInCells.Characteristic AS Characteristic,
	|	Assignments.Ref AS Purpose,
	|	SUM(RegisterDataInCells.Demand) AS Demand,
	|	SUM(RegisterDataInCells.Demand) - MAX(ISNULL(DocumentData.Count, 0)) AS Balance,
	|	SUM(0) AS Supplied,
	|	Assignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters
	|FROM
	|	(SELECT
	|		GoodsInStorageBinsBalance.Products AS Products,
	|		GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|		GoodsInStorageBinsBalance.Purpose AS Purpose,
	|		GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance AS Demand
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins.Balance(
	|				,
	|				Characteristic = &Characteristic
	|					AND Products IN (&Products)
	|					AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|					AND Cell = &Cell) AS GoodsInStorageBinsBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInStorageBins.Products,
	|		GoodsInStorageBins.Characteristic,
	|		GoodsInStorageBins.Purpose,
	|		CASE
	|			WHEN GoodsInStorageBins.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN GoodsInStorageBins.ForPicking
	|			ELSE GoodsInStorageBins.InStock
	|		END
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins AS GoodsInStorageBins
	|	WHERE
	|		GoodsInStorageBins.Products IN (&Products)
	|		AND GoodsInStorageBins.Characteristic = &Characteristic
	|		AND GoodsInStorageBins.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND GoodsInStorageBins.Recorder = &Recorder) AS RegisterDataInCells
	|		LEFT JOIN GoodsOfDocumentAreGrouped AS DocumentData
	|		ON RegisterDataInCells.Products = DocumentData.Products
	|			AND RegisterDataInCells.Characteristic = DocumentData.Characteristic
	|			AND RegisterDataInCells.Purpose = DocumentData.Purpose
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON RegisterDataInCells.Purpose = Assignments.Ref
	|WHERE
	|	RegisterDataInCells.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND RegisterDataInCells.Purpose.RecordsInWarehouseRegisters
	|
	|GROUP BY
	|	RegisterDataInCells.Products,
	|	RegisterDataInCells.Characteristic,
	|	Assignments.Ref";
	
	If RequestFormationParameters.TakeIntoAccountAlreadySelected Then
		// The request is not for dynamic lists
		QueryText =
		"SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Purpose,
		|	DocumentGoods.Count
		|INTO TableOfDocumentProducts
		|FROM
		|	&DocumentGoods AS DocumentGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfDocumentProducts.Products AS Products,
		|	TableOfDocumentProducts.Characteristic AS Characteristic,
		|	TableOfDocumentProducts.Purpose AS Purpose,
		|	SUM(TableOfDocumentProducts.Count) AS Count
		|INTO GoodsOfDocumentAreGrouped
		|FROM
		|	TableOfDocumentProducts AS TableOfDocumentProducts
		|WHERE
		|	TableOfDocumentProducts.Products IN (&Products) AND TableOfDocumentProducts.Characteristic = &Characteristic
		|
		|GROUP BY
		|	TableOfDocumentProducts.Products,
		|	TableOfDocumentProducts.Characteristic,
		|	TableOfDocumentProducts.Purpose
		|;" + QueryText;
	Else
		QueryText = StrReplace(QueryText, "GoodsOfDocumentAreGrouped", "(" +
			"SELECT
			|	TRUE AS Products,
			|	TRUE AS Characteristic,
			|	TRUE AS Purpose,
			|	0 AS Count" + ")");
	EndIf;

	If RequestFormationParameters.SortByDateOfAppointmentOrder Then
		QueryText = QueryText + "
		|ORDER BY
		|	Assignments.OrderDocument.Date";
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the query text for unsecured assignments with quantitative characteristics 
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextOfUnsecuredAppointmentsSecured(RequestFormationParameters) Export
	
	QueryText =
		"SELECT
		|	Assignments.Ref AS Purpose,
		|	Assignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters,
		|	Set.ReserveAtWarehouseBalance
		|		+ Set.ReserveAtWarehouseFromLockedBalance
		|		+ Set.ReserveAsReceivedBalance
		|		+ Set.ReserveUponReceiptFromLockedBalance
		|		+ Set.SnoozeReservationBalance
		|		+ Set.ToSupplyBalance AS Demand,
		|	Set.ReserveAtWarehouseBalance
		|		+ Set.ReserveAtWarehouseFromLockedBalance
		|		+ Set.ReserveAsReceivedBalance
		|		+ Set.ReserveUponReceiptFromLockedBalance
		|		+ Set.SnoozeReservationBalance
		|		+ Set.ToSupplyBalance
		|		- Set.InStockBalance
		|		- Set.OrderedBalance AS ToOrder,
		|	Set.InStockBalance AS Supplied
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND Products  IN (&Products)
		|		AND Warehouse = &Warehouse
		|		AND Characteristic = &Characteristic) AS Set
		|		
		|		INNER JOIN Catalog.Assignments AS Assignments
		|		ON Assignments.Ref = Set.Purpose
		|WHERE
		|	Assignments.Ref = &Purpose
		|		OR Set.ReserveAtWarehouseBalance
		|		+ Set.ReserveAtWarehouseFromLockedBalance
		|		+ Set.ReserveAsReceivedBalance
		|		+ Set.ReserveUponReceiptFromLockedBalance
		|		+ Set.SnoozeReservationBalance
		|		+ Set.ToSupplyBalance <> 0
		|		OR Set.ReserveAtWarehouseBalance
		|		+ Set.ReserveAtWarehouseFromLockedBalance
		|		+ Set.ReserveAsReceivedBalance
		|		+ Set.ReserveUponReceiptFromLockedBalance
		|		+ Set.SnoozeReservationBalance
		|		+ Set.ToSupplyBalance
		|		- Set.OrderedBalance <> 0
		|		- Set.InStockBalance <> 0
		|		OR Set.InStockBalance <> 0";
	
	If RequestFormationParameters.SortByDateOfAppointmentOrder Then
		QueryText = QueryText + "
		|ORDER BY
		|	Set.Purpose.OrderDocument.Date";
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the request text for all assignments for this item and characteristic
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAllAppointments(RequestFormationParameters) Export
	
	QueryText =
	"SELECT DISTINCT
	|	CatalogAssignments.Ref AS Purpose,
	|	CatalogAssignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters,
	|	CatalogAssignments.DataVersion AS DataVersion,
	|	CatalogAssignments.DeletionMark AS DeletionMark,
	|	CatalogAssignments.Predefined AS Predefined,
	|	CatalogAssignments.Description AS Description
	|FROM
	|	Catalog.Assignments AS CatalogAssignments
	|		
	|		LEFT JOIN AccumulationRegister.InventoryAndDemands AS RegisterRecords
	|		ON RegisterRecords.Purpose = CatalogAssignments.Ref
	|WHERE
	|	RegisterRecords.Active
	|		AND RegisterRecords.Products = &Products
	|		AND RegisterRecords.Characteristic = &Characteristic
	|		AND RegisterRecords.Warehouse = &Warehouse";
	
	If RequestFormationParameters.SortByDateOfAppointmentOrder Then
		QueryText = QueryText + "
		|ORDER BY
		|	CatalogAssignments.OrderDocument.Date";
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region InteractionWithAssignmentSelectionForm

Function RequestTextAndParametersTermsOfUse(Prefix, TermsOfUse_) Export
	
	ThereIsSpecialSymbol = StrFind(TermsOfUse_, "&") <> 0;
	
	SubstringsOfExpressions = ?(ThereIsSpecialSymbol,
		StrSplit(TermsOfUse_, "&", False),
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(TermsOfUse_, "Object.", True));
	
	SetOfRequestConditions = New Array();
	ListOfRequestParameters = New Array();
	
	For Each SubstringOfExpression In SubstringsOfExpressions Do
		
		If Not ThereIsSpecialSymbol Then
			SubstringOfExpression = "Object." + SubstringOfExpression;
		EndIf;
		
		ObjectExpression = Mid(SubstringOfExpression, 1, StrFind(SubstringOfExpression, " ") - 1);
		
		BeginningOfLastWord = StrFind(ObjectExpression, ".", SearchDirection.FromEnd);
		LastWord = Mid(ObjectExpression, BeginningOfLastWord + 1);
		
		LeftSideOfParameterName = ?(ValueIsFilled(Prefix), Prefix + "_", "");
		ParameterName = LeftSideOfParameterName + LastWord;
		ParameterName = TrimAll(ParameterName);
		
		QueryCondition = StrReplace(SubstringOfExpression, ObjectExpression, "&" + ParameterName);
		
		SetOfRequestConditions.Add(QueryCondition);
		ListOfRequestParameters.Add(ParameterName);
		
	EndDo;
	
	QueryConditions = StrConcat(SetOfRequestConditions, Chars.LF);
	
	If IsBlankString(QueryConditions) Then
		QueryConditions = "FALSE";
	EndIf;
	
	QueryText =
		"SELECT
		|	&QueryConditions AS ConditionMet";
	QueryText = StrReplace(QueryText, "&QueryConditions", QueryConditions);
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("QueryText", QueryText);
	ReturnStructure.Insert("QueryOptions", ListOfRequestParameters);
	
	Return ReturnStructure;
	
EndFunction

Function DataPathsTermsOfUse(Prefix, TermsOfUse_, PathToTheDestinationField, FormTable, PathToTabularSection)
	
	DataPaths = New Structure();
	
	ObjectExpressions = ExpressionsOfPathsToTermsOfUseData(TermsOfUse_);
	
	For Each ObjectExpression In ObjectExpressions Do
		
		ObjectExpression = TrimAll(ObjectExpression);
		
		DataPath = GenerateDataPath(ObjectExpression, PathToTheDestinationField, FormTable, PathToTabularSection);
		
		BeginningOfLastWordOfPath = StrFind(DataPath, ".", SearchDirection.FromEnd);
		LastWordOfWay = Mid(DataPath, BeginningOfLastWordOfPath + 1);
		
		LeftSideOfParameterName = ?(ValueIsFilled(Prefix), Prefix + "_", "");
		ParameterName = LeftSideOfParameterName + LastWordOfWay;
		
		DataPaths.Insert(ParameterName, DataPath);
		
	EndDo;
	
	Return DataPaths;
	
EndFunction

// Parameters:
//  Parameters - Structure - structure of parameters.
// 
// Returns:
//   ValueList - Selection data.
Function FillInSelectionData(Parameters) Export
	
	ChoiceData = New ValueList;
	
	ManagerOfDocument = Common.ObjectManagerByRef(Parameters.Source);
	
	AssignmentSelectionFormTemplate = ManagerOfDocument.AssignmentSelectionFormTemplate();
	
	QueryOptions = GenerateRequestParametersBasedOnTemplateOfAssignmentForm(AssignmentSelectionFormTemplate, Parameters);
	
	QueryText = GenerateQueryTextSelectionData(AssignmentSelectionFormTemplate, QueryOptions);
	
	Query = New Query();
	Query.SetParameter("Source", Parameters.Source);
	Query.Text = QueryText;
	
	// Setting the values of the request parameters.
	
	For Each DescriptionOfColumns In AssignmentSelectionFormTemplate.ColumnDescriptions Do
		
		If DescriptionOfColumns.PathToTheDestinationField <> QueryOptions.PathToTheDestinationField Then
			Continue;
		EndIf;
		
		For Each DataPath In DescriptionOfColumns.DataPaths Do
			ParameterName = DescriptionOfColumns.Prefix + "_" + DataPath.Key;
			Value = QueryOptions[ParameterName];
			Query.SetParameter(ParameterName, Value);
		EndDo;
		
	EndDo;
	
	For Each DestinationPattern In AssignmentSelectionFormTemplate.AssignmentTemplates Do
		
		If Not CheckUsageConditions("", DestinationPattern.TermsOfUse_,
			Parameters, DestinationPattern.PathToTheDestinationField) Then
			Continue;
		EndIf;
		
		For Each FilterField In DestinationPattern Do
			If FilterField.Key = "PathToTheDestinationField"
				Or FilterField.Key = "ExcludeRefAssignment"
				Or FilterField.Key = "VisibleSelectionsOnForm" Then
				Continue;
			EndIf;
			
			If ValueIsFilled(FilterField.Value)
				// will not work for expressions from PM and expressions from IB
				And (StrFind(FilterField.Value, "Object.") <> 0
					Or StrFind(FilterField.Value, "&") <> 0) Then
				
				TermsOfUseParameters = RequestTextAndParametersTermsOfUse("", FilterField.Value);
				For Each QueryParameter In TermsOfUseParameters.QueryOptions Do
					ParameterValue = QueryOptions[QueryParameter];
					Query.SetParameter(QueryParameter, ParameterValue);
				EndDo;
			EndIf;
		EndDo;
		
	EndDo;
	
	Query.SetParameter("AssignmentTypes", QueryOptions.AssignmentTypes);
	Query.SetParameter("SearchString", "%" + Parameters.SearchString + "%");
	
	SelectedDestinations = Query.Execute().Unload().UnloadColumn("Purpose");
	
	ChoiceData.LoadValues(SelectedDestinations);
	
	Return ChoiceData;
	
EndFunction

Function CheckUsageConditions(Prefix, TermsOfUse_, QueryOptions, PathToTheDestinationField = "") Export
	
	If Not IsBlankString(PathToTheDestinationField)
		And PathToTheDestinationField <> QueryOptions.PathToTheDestinationField Then
		Return False;
	EndIf;
	
	If IsBlankString(TermsOfUse_)
		Or StrFind(TermsOfUse_, "Object.") = 0
			And StrFind(TermsOfUse_, "&") = 0 Then
		Return True;
	EndIf;
	
	TermsOfUseParameters = RequestTextAndParametersTermsOfUse(Prefix, TermsOfUse_);
	
	Query = New Query();
	Query.Text = TermsOfUseParameters.QueryText;
	
	For Each QueryParameter In TermsOfUseParameters.QueryOptions Do
		Query.SetParameter(QueryParameter, QueryOptions[QueryParameter]);
	EndDo;
	
	QueryResult = Query.Execute().Select();
	
	QueryResult.Next();
	
	Return QueryResult.ConditionMet;
	
EndFunction

Function GenerateRequestParametersBasedOnTemplateOfAssignmentForm(AssignmentFormTemplate, SourceOfParameters) Export
	
	QueryOptions = New Structure();
	QueryOptions.Insert("PathToTheDestinationField", SourceOfParameters.PathToTheDestinationField);
	
	SourceOfParametersObtainedFromInformationSecurity = New Map();
	For Each DescriptionOfColumns In AssignmentFormTemplate.ColumnDescriptions Do
		
		If DescriptionOfColumns.PathToTheDestinationField <> SourceOfParameters.PathToTheDestinationField Then
			Continue;
		EndIf;
		
		SourceOfParametersObtainedFromInformationSecurity(
			DescriptionOfColumns.Prefix,
			DescriptionOfColumns.TermsOfUse_,
			DescriptionOfColumns.PathToTheDestinationField,
			SourceOfParametersObtainedFromInformationSecurity);
		
		For Each DataPath In DescriptionOfColumns.DataPaths Do
			If StrFind(DataPath.Value, "Object.") > 0 Then
				SourceOfParametersObtainedFromInformationSecurity(
					DescriptionOfColumns.Prefix,
					DataPath.Value,
					DescriptionOfColumns.PathToTheDestinationField,
					SourceOfParametersObtainedFromInformationSecurity);
			EndIf;
		EndDo;
		
	EndDo;
	
	FillInParameterValueFromIB(SourceOfParametersObtainedFromInformationSecurity, SourceOfParameters);
	
	For Each DescriptionOfColumns In AssignmentFormTemplate.ColumnDescriptions Do
		
		If DescriptionOfColumns.PathToTheDestinationField <> SourceOfParameters.PathToTheDestinationField Then
			Continue;
		EndIf;
		For Each DataPath In DescriptionOfColumns.DataPaths Do
			ParameterName = DescriptionOfColumns.Prefix + "_" + DataPath.Key;
			FormParameter = New Structure(ParameterName);
			FillPropertyValues(FormParameter, SourceOfParameters);
			Value = FormParameter[ParameterName];
			RequestParameterReceivedFromInformationSecurity = SourceOfParametersObtainedFromInformationSecurity.Get(ParameterName);
			If RequestParameterReceivedFromInformationSecurity <> Undefined Then
				Value = RequestParameterReceivedFromInformationSecurity.Value;
			EndIf;
			QueryOptions.Insert(ParameterName, Value);
		EndDo;
		
		TermsOfUseParameters = RequestTextAndParametersTermsOfUse(DescriptionOfColumns.Prefix, DescriptionOfColumns.TermsOfUse_);
		For Each QueryParameter In TermsOfUseParameters.QueryOptions Do
			If Not QueryOptions.Property(QueryParameter) Then
				
				RequestParameterReceivedFromInformationSecurity = SourceOfParametersObtainedFromInformationSecurity.Get(QueryParameter);
				If RequestParameterReceivedFromInformationSecurity <> Undefined Then
					
					ParameterValue = RequestParameterReceivedFromInformationSecurity.Value;
					
				Else
					
					ParameterValue = SourceOfParameters[QueryParameter];
					
				EndIf;
				QueryOptions.Insert(QueryParameter, ParameterValue);
				
			EndIf;
		EndDo;
		
	EndDo;
	
	ExcludeRefAssignment = False;
	For Each DestinationPattern In AssignmentFormTemplate.AssignmentTemplates Do
		
		If Not CheckUsageConditions("", DestinationPattern.TermsOfUse_,
			SourceOfParameters, DestinationPattern.PathToTheDestinationField) Then
			Continue;
		EndIf;
		
		ExcludeRefAssignment = ExcludeRefAssignment Or DestinationPattern.ExcludeRefAssignment;
		If Not IsBlankString(DestinationPattern.TermsOfUse_)
			And (StrFind(DestinationPattern.TermsOfUse_, "Object.") <> 0
				Or StrFind(DestinationPattern.TermsOfUse_, "&") <> 0) Then
			TermsOfUseParameters = RequestTextAndParametersTermsOfUse("", DestinationPattern.TermsOfUse_);
			For Each QueryParameter In TermsOfUseParameters.QueryOptions Do
				QueryOptions.Insert(QueryParameter, SourceOfParameters[QueryParameter]);
			EndDo;
		EndIf;
		
		For Each FilterField In DestinationPattern Do
			If FilterField.Key = "PathToTheDestinationField" Then
				Continue;
			EndIf;
			If FilterField.Key = "AssignmentTypes" Then
				QueryOptions.Insert("AssignmentTypes", FilterField.Value);
			ElsIf ValueIsFilled(FilterField.Value)
				And (StrFind(FilterField.Value, "Object.") <> 0
					Or StrFind(FilterField.Value, "&") <> 0) Then
				
				TermsOfUseParameters = RequestTextAndParametersTermsOfUse("", FilterField.Value);
				For Each QueryParameter In TermsOfUseParameters.QueryOptions Do
					QueryOptions.Insert(QueryParameter, SourceOfParameters[QueryParameter]);
				EndDo;
			EndIf;
		EndDo;
		
	EndDo;
	
	// If there are no assignment templates in the layout
	If Not QueryOptions.Property("AssignmentTypes") Then
		QueryOptions.Insert("AssignmentTypes", New Array);
		For Each Value In Enums.AssignmentTypes Do
			QueryOptions.AssignmentTypes.Add(Value);
		EndDo;
		ExcludeRefAssignment = True;
	EndIf;
	QueryOptions.Insert("ExcludeRefAssignment", ExcludeRefAssignment);
	
	Return QueryOptions;
	
EndFunction

Procedure AddPartnerExclusionCondition(Conditions, Source) Export
	
	ThereAreAppointmentsWithCompletedPartner = False;
	ThereAreAppointmentsWithCompletedPartner =
		ThereAreAppointmentsWithCompletedPartner
		Or GetFunctionalOption("UseProductionByThirdParty2_5");
	ThereAreAppointmentsWithCompletedPartner =
		ThereAreAppointmentsWithCompletedPartner
		Or GetFunctionalOption("UseTollManufacturing2_5");
	ThereAreAppointmentsWithCompletedPartner = ThereAreAppointmentsWithCompletedPartner Or GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	
	If Not ThereAreAppointmentsWithCompletedPartner Then
			
			Conditions.Add(Source + ".Partner = VALUE(Catalog.Partners.EmptyRef)");
			
	EndIf;
	
EndProcedure

Procedure AddPartnerExclusionSelection(FiltersStructure) Export
	
	ThereAreAppointmentsWithCompletedPartner = False;
	
	ThereAreAppointmentsWithCompletedPartner =
		ThereAreAppointmentsWithCompletedPartner
		Or GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	ThereAreAppointmentsWithCompletedPartner =
		ThereAreAppointmentsWithCompletedPartner
		Or GetFunctionalOption("UseProductionByThirdParty2_5");
	ThereAreAppointmentsWithCompletedPartner =
		ThereAreAppointmentsWithCompletedPartner
		Or GetFunctionalOption("UseTollManufacturing2_5");
	If Not ThereAreAppointmentsWithCompletedPartner Then
			
			FiltersStructure.Insert("Partner", Catalogs.Partners.EmptyRef());
			
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region UpdatingAssignmentsInTabularPartsOfDocuments

Function TemplatesFromLinks(ReferencesArrray) Export
	
	Query = New Query();
	Query.Text =
		"SELECT DISTINCT
		|	Table.Ref                  AS Ref,
		|	Table.LineOfBusiness AS LineOfBusiness,
		|	Table.Partner                 AS Partner,
		|	Table.Contract                 AS Contract,
		|	Table.AssignmentType           AS AssignmentType,
		|	Table.OrderDocument                   AS OrderDocument
		|FROM
		|	Catalog.Assignments AS Table
		|WHERE
		|	Table.Ref IN(&ReferencesArrray)";
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	Result = New Map();
	While Selection.Next() Do
		
		Template = NewSubmenuTemplate();
		FillPropertyValues(Template, Selection);
		Result.Insert(Selection.Ref, Template);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function TemplateIsSpecialCaseOfTemplate(TemplatePrivate, TemplateIsCommon) Export
	
	For Each Property In TemplateIsCommon Do
		
		If ValueIsFilled(Property.Value) And TemplatePrivate[Property.Key] <> TemplateIsCommon[Property.Key] Then
			Return False;
		EndIf;
		
	EndDo;
	Return True;
	
EndFunction

Procedure FillInSecurityAssignment(TabularSection, HeaderAssignment, NameOfSecurityDestinationField = "SupplyAssignment") Export

	Query = New Query(
	"SELECT
	|	Goods.LineNumber - 1 AS RowIndex,
	|	Goods.Purpose      AS Purpose
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.RowIndex AS RowIndex,
	|	CASE WHEN TTProducts_1.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			OR Assignments.AssignmentType = VALUE(Enum.AssignmentTypes.Own) THEN
	|		&HeaderAssignment
	|	ELSE
	|		TTProducts_1.Purpose
	|	END AS SupplyAssignment
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON TTProducts_1.Purpose = Assignments.Ref");
	
	Query.SetParameter("Goods", ?(TypeOf(TabularSection) = Type("ValueTable"),
		TabularSection, TabularSection.Unload(, "LineNumber, Purpose")));
	Query.SetParameter("HeaderAssignment", HeaderAssignment);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TabularSection[Selection.RowIndex][NameOfSecurityDestinationField] = Selection.SupplyAssignment;
	EndDo;

EndProcedure

#EndRegion

#Region CreatingAppointments

Function CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject, VerificationDetails_1, Cancel, ForNewOnesAlwaysCreate = False, Clear = False) Export
	
	// Checks that the assignment in the object is correct.
	// If the assignment is incorrect, it corrects it:
	//  - either searches for the correct destination in the database ,
	//  - or returns a link to a new destination if the search does not yield results.
	
	UpdatedAssignment = False;
	
	// For a new object, the destination is always updated.
	If ThisObject.IsNew() Then
		
		UpdatedAssignment = True;
		
		// The assignment in the object is not used, so you need to clear it.
		If Clear Then
			
			Purpose = Undefined;
			
		// There is a link to the object being created in the template, so there is no point in looking for the correct purpose in the database, it is not there.
		// The assignment will need to be created when writing the object.
		ElsIf ForNewOnesAlwaysCreate Or LinkIsInTemplate(ThisObject.Ref, DestinationPattern) Then
			
			Purpose = Catalogs.Assignments.GetRef();
			
		// The assignment is an assignment associated with another object, so it is in the database. We need to find him.
		Else
			
			// An appointment related to a partner and a line of business or a contract and a line of business other than
			// that specified in the contract are created only at the time of fixing the need.
			If ValueIsFilled(DestinationPattern.Partner)
				And Not (DestinationPattern.LineOfBusiness.IsEmpty() And DestinationPattern.Contract.IsEmpty()
					And DestinationPattern.AssignmentType = Enums.AssignmentTypes.Own) Then
				
				// We will set a lock to exclude the possibility of creating a duplicate by another object generating the same assignment at this time.
				SetPatternLock(DestinationPattern);
				
				Purpose = FindByTemplate(DestinationPattern);
				
				If Not ValueIsFilled(Purpose) Then
					
					Purpose = Catalogs.Assignments.GetRef();
					
				EndIf;
				
			Else
				
				Purpose = FindByTemplate(DestinationPattern);
				
				If Not ValueIsFilled(Purpose) Then
					
					Cancel = True;
					CommonClientServer.MessageToUser(MessageNoDestinationInDatabase(DestinationPattern));
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	// If the object is being recorded repeatedly, the assignment should be updated if the key details of the object have changed.
	ElsIf VerificationDetails_1 <> "" Then
		
		ObjectInInfobase = Common.ObjectAttributesValues(ThisObject.Ref, VerificationDetails_1);
		If Not TMCommonUseClientServer.StructuresAreEqual(ThisObject, ObjectInInfobase, VerificationDetails_1)
				Or Not ValueIsFilled(Purpose) Then // the assignment could be cleared if the key details were changed in the form after switching the option.
			
			UpdatedAssignment = True;
			
			// The assignment in the object is not used, so you need to clear it.
			If Clear Then
				
				Purpose = Undefined;
				
			// The assignment could already be recorded in the database if the details of the object are changed "back and forth" and such a combination was already in the object.
			// If not, then it will need to be created when writing the object.
			ElsIf LinkIsInTemplate(ThisObject.Ref, DestinationPattern) Then
				
				Purpose = FindByTemplate(DestinationPattern);
				If Not ValueIsFilled(Purpose) Then
					Purpose = Catalogs.Assignments.GetRef(); // this is a record of an object with new values of key details
				EndIf;
				
			// The assignment is an assignment associated with another object, so it is in the database. We need to find him.
			Else
				
				// An appointment related to a partner and a line of business or a contract and a line of business other than
				// that specified in the contract are created only at the time of fixing the need.
				If ValueIsFilled(DestinationPattern.Partner)
					And Not (DestinationPattern.LineOfBusiness.IsEmpty() And DestinationPattern.Contract.IsEmpty()
						And DestinationPattern.AssignmentType = Enums.AssignmentTypes.Own) Then
						
					// We will set a lock to exclude the possibility of creating a duplicate by another object generating the same assignment at this time.
					SetPatternLock(DestinationPattern);
					
					Purpose = FindByTemplate(DestinationPattern);
					
					If Not ValueIsFilled(Purpose) Then
						Purpose = Catalogs.Assignments.GetRef();
					EndIf;
					
				Else
					
					Purpose = FindByTemplate(DestinationPattern);
					
					If Not ValueIsFilled(Purpose) Then
						
						Cancel = True;
						CommonClientServer.MessageToUser(MessageNoDestinationInDatabase(DestinationPattern));
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return UpdatedAssignment;
	
EndFunction

Procedure OnWriteDocument(Purpose, DestinationPattern, ThisObject, Recipient, VATActivityType) Export
	
	If Not ValueIsFilled(Purpose) Then
		Return;
	EndIf;
	
	DocumentAttributes = New Structure("Number, Date, DeletionMark");
	FillPropertyValues(DocumentAttributes, ThisObject);
	DocumentAttributes.Insert("Recipient",         Recipient);
	DocumentAttributes.Insert("VATActivityType", VATActivityType);
	
	SetPrivilegedMode(True);
	DetailsOfAppointment = Common.ObjectAttributesValues(Purpose,
		"Description,
		|DeletionMark,
		|OrderDocument,
		|LineOfBusiness,
		|Partner,
		|Contract,
		|VATActivityType,
		|AssignmentType");
	
	If DetailsOfAppointment.Description <> Undefined Then
		
		PurposePresentation = PresentationOfDestinationForRecordingInInformationBase(
			DetailsOfAppointment,
			DocumentAttributes);
		
		UpdateDeleteMark    = ValueIsFilled(DetailsOfAppointment.OrderDocument)
			And DetailsOfAppointment.DeletionMark <> DocumentAttributes.DeletionMark;
		UpdateVATActivity = ValueIsFilled(DetailsOfAppointment.OrderDocument)
			And DetailsOfAppointment.VATActivityType <> DocumentAttributes.VATActivityType;
		UpdateDescription = DetailsOfAppointment.Description <> PurposePresentation;

		If UpdateDeleteMark
			Or UpdateVATActivity
			Or UpdateDescription Then
			
			DestinationObject = Purpose.GetObject();
			
			If UpdateDeleteMark Then
				DestinationObject.DeletionMark = DocumentAttributes.DeletionMark;
			EndIf;
			
			If UpdateVATActivity Then
				DestinationObject.VATActivityType = DocumentAttributes.VATActivityType;
			EndIf;
			
			If UpdateDescription Then
				DestinationObject.Description = PurposePresentation;
			EndIf; 
			
			DestinationObject.Write();
			
		EndIf;
		
	Else // This is a new assignment
		
		PurposePresentation = PresentationOfDestinationForRecordingInInformationBase(
			DestinationPattern,
			DocumentAttributes);
		
		DestinationObject = Catalogs.Assignments.CreateItem();
		DestinationObject.SetNewObjectRef(Purpose);
		
		DestinationObject.LineOfBusiness = DestinationPattern.LineOfBusiness;
		DestinationObject.Partner                 = DestinationPattern.Partner;
		DestinationObject.Contract                 = DestinationPattern.Contract;
		DestinationObject.OrderDocument                   = DestinationPattern.OrderDocument;
		DestinationObject.AssignmentType           = DestinationPattern.AssignmentType;
		DestinationObject.Description            = PurposePresentation;
		If ValueIsFilled(DestinationPattern.OrderDocument) Then
			DestinationObject.DeletionMark    = DocumentAttributes.DeletionMark;
			DestinationObject.VATActivityType = DocumentAttributes.VATActivityType;
		EndIf;
		
		If DestinationObject.AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal Then
			DestinationObject.ConsiderVATRates = True;
		EndIf;
		
		DestinationObject.Write();
		
	EndIf;
	
EndProcedure

Procedure WhenWritingCatalog(Purpose, DestinationPattern, ThisObject, VATActivityType, UpdateAssignment = False) Export
	
	If Not ValueIsFilled(Purpose) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	DetailsOfAppointment = Common.ObjectAttributesValues(Purpose,
		"Description, DeletionMark, OrderDocument, LineOfBusiness, Partner, Contract, VATActivityType, AssignmentType");
	
	If DetailsOfAppointment.Description <> Undefined Then
		
		PurposePresentation = PresentationOfDestinationForRecordingInInformationBase(
			DetailsOfAppointment,
			Undefined);
		
		UpdateDeleteMark    = DetailsOfAppointment.DeletionMark <> ThisObject.DeletionMark;
		UpdateVATActivity = DetailsOfAppointment.VATActivityType <> VATActivityType;
		UpdateDescription       = DetailsOfAppointment.Description <> PurposePresentation;
		
		If UpdateAssignment
			Or UpdateDeleteMark
			Or UpdateVATActivity
			Or UpdateDescription Then
			
			DestinationObject = Purpose.GetObject();
			
			If UpdateDeleteMark Then
				DestinationObject.DeletionMark = ThisObject.DeletionMark;
			EndIf;
			
			If UpdateVATActivity Then
				DestinationObject.VATActivityType = VATActivityType;
			EndIf;
			
			If UpdateDescription Then
				DestinationObject.Description = PurposePresentation;
			EndIf;
			
			DestinationObject.Write();
			
		EndIf;
		
	Else // This is a new assignment
		
		PurposePresentation = PresentationOfDestinationForRecordingInInformationBase(
			DestinationPattern,
			Undefined);
		
		DestinationObject = Catalogs.Assignments.CreateItem();
		DestinationObject.SetNewObjectRef(Purpose);
		
		DestinationObject.LineOfBusiness = DestinationPattern.LineOfBusiness;
		DestinationObject.Partner                 = DestinationPattern.Partner;
		DestinationObject.Contract                 = DestinationPattern.Contract;
		DestinationObject.OrderDocument                   = DestinationPattern.OrderDocument;
		DestinationObject.AssignmentType           = DestinationPattern.AssignmentType;
		DestinationObject.Description            = PurposePresentation;
		DestinationObject.DeletionMark         = ThisObject.DeletionMark;
		DestinationObject.VATActivityType      = VATActivityType;
		
		If DestinationObject.AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal Then
			DestinationObject.ConsiderVATRates = True;
		EndIf;
		
		DestinationObject.Write();
		
	EndIf;
	
EndProcedure

Function PatternsAreEqual(Template1, Template2) Export
	
	For Each Property In Template1 Do
		
		If Template1[Property.Key] <> Template2[Property.Key] Then
			Return False;
		EndIf;
		
	EndDo;
	Return True;
	
EndFunction

// Returns:
//  Structure - Structure:
//   * LineOfBusiness - CatalogRef.LinesOfBusiness -
//   * Partner - CatalogRef.Partners -
//   * Contract - CatalogRef.CounterpartyContracts -
//   * OrderDocument - DefinedType.ExpectedShipmentOrReceipt, Undefined -
//   * AssignmentType - EnumRef.AssignmentTypes -
Function NewSubmenuTemplate() Export
	
	Result = New Structure();
	Result.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	Result.Insert("Partner", Catalogs.Partners.EmptyRef());
	Result.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	Result.Insert("OrderDocument", Undefined);
	Result.Insert("AssignmentType", Enums.AssignmentTypes.Own);
	
	Return Result;
	
EndFunction

Function FindByTemplate(Template) Export
	
	Result = Undefined;
	
	Query = New Query();
	Query.Text =
	"SELECT TOP 1
	|	Assignments.Ref AS Ref
	|FROM
	|	Catalog.Assignments AS Assignments
	|WHERE
	|	Assignments.LineOfBusiness = &LineOfBusiness
	|	AND Assignments.Partner = &Partner
	|	AND Assignments.Contract = &Contract
	|	AND Assignments.OrderDocument = &OrderDocument
	|	AND Assignments.AssignmentType = &AssignmentType";
	
	Query.SetParameter("LineOfBusiness", Template.LineOfBusiness);
	Query.SetParameter("Partner",                 Template.Partner);
	Query.SetParameter("Contract",                 Template.Contract);
	Query.SetParameter("OrderDocument",                   Template.OrderDocument);
	Query.SetParameter("AssignmentType",           Template.AssignmentType);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function PresentationOfDestinationForRecordingInInformationBase(KeyFields, DocumentAttributes)
	
	PurposePresentation = Undefined;
	
	FieldArray = New Array;
	
	If ValueIsFilled(KeyFields.OrderDocument) Then
		
		FieldArray.Add(DocumentAttributes.Recipient);
		
		If ValueIsFilled(KeyFields.LineOfBusiness) Then
			FieldArray.Add(KeyFields.LineOfBusiness);
		EndIf;
		
		If ValueIsFilled(KeyFields.Partner) Then
			FieldArray.Add(?(ValueIsFilled(KeyFields.Contract), KeyFields.Contract, KeyFields.Partner));
		EndIf;
		
		OrderNumber = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(DocumentAttributes.Number);
		FieldArray.Add(OrderNumber);
		
		FieldArray.Add(Format(DocumentAttributes.Date, "DLF=D"));
		
	ElsIf ValueIsFilled(KeyFields.Contract) Then
		
		FieldArray.Add(KeyFields.Contract);
		
		If ValueIsFilled(KeyFields.LineOfBusiness) Then
			FieldArray.Add(KeyFields.LineOfBusiness);
		EndIf;
		
	ElsIf ValueIsFilled(KeyFields.Partner) Then
		
		FieldArray.Add(KeyFields.Partner);
		
		If ValueIsFilled(KeyFields.LineOfBusiness) Then
			FieldArray.Add(KeyFields.LineOfBusiness);
		EndIf;
		
	Else
		
		FieldArray.Add(KeyFields.LineOfBusiness);
		
	EndIf;
	
	PurposePresentation = StrConcat(FieldArray, ", ");
	DefaultLanguageCode = Common.DefaultLanguageCode();
	DestinationTypePresentation = AssignmentsClientServer.DestinationTypePresentation(KeyFields, DefaultLanguageCode);
	PurposePresentation = PurposePresentation + " (" + DestinationTypePresentation + ")";
	
	Return PurposePresentation;
	
EndFunction

Procedure SetPatternLock(Template)
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.Assignments");
	For Each TemplateField_1 In Template Do
		LockItem.SetValue(TemplateField_1.Key, TemplateField_1.Value);
	EndDo;
	Block.Lock();
	
EndProcedure

#Region SelectingAssignmentsInDocuments


// The layout of the description column
// 
// Returns:
// 	Structure - LongDesc:
// * SpeakersAreNotSwitchedOff - Array - so I don't have speakers
// * DefaultColumns - Array - default columns
// * Columns - ValueList - Columns
// * DataPaths - Structure - Data paths
// * PathToTheDestinationField - String - path to the Destination field
// * PathToTabularSection - String - the path to the tabular part of the destination field should be set only if it is not the tabular part of the object
// * Cancel - Boolean - Cancel
// * TermsOfUse_ - String - condition of use
// * QueryText - String - Query text
// * TemporaryTable - Undefined,String - The Query Text Of Temporary Tables
// * Prefix - String - prefix,
// * FormItemName - String - name of the form element associated with the assignment
// * FormTableName - String - the name of the table element of the form in which the destination field is located
Function ColumnDescriptionTemplate()
	
	DescriptionOfColumns = New Structure();
	
	// The unique name of the data source. By default, it is equal to the name of the data source.
	// If the same source is used more than once,
	// an individual prefix should be specified for each of them.
	DescriptionOfColumns.Insert("Prefix",              "");
	
	// The text of the data source request
	DescriptionOfColumns.Insert("QueryText",         "");
	
	// Time Table Query Text
	DescriptionOfColumns.Insert("TemporaryTable", Undefined);
	
	// An expression that determines whether to display the columns specified by the current layout.
	// For example, "Object.Products.Nomenclature Type <> VALUE(Enumeration.Types of nomenclature.Work)".
	DescriptionOfColumns.Insert("TermsOfUse_", "");
	
	// A sign that is filled in according to certain rules, in the method of adding a description of columns.
	DescriptionOfColumns.Insert("Cancel",                False);
	
	// For example, "Object.Purpose", or "Object.Products.Appointment".
	DescriptionOfColumns.Insert("PathToTheDestinationField",  "");
	
	// Data paths are query parameters whose values will be obtained from the document context.
	// The key is the name of the request parameter, the Value is the source of the value, for example, "Object.Warehouse".
	DescriptionOfColumns.Insert("DataPaths",          New Structure);
	
	// Columns that can be shown in the selection list.
	// Important - the order of adding columns to the list must match the order of the selected fields in the query.
	DescriptionOfColumns.Insert("Columns",              New ValueList);
	
	// An array of column names that must be shown to the user immediately when opening the form.
	DescriptionOfColumns.Insert("DefaultColumns",   New Array);
	
	// Array of column names whose disabling is not available to the user.
	DescriptionOfColumns.Insert("SpeakersAreNotSwitchedOff", New Array);
	
	DescriptionOfColumns.Insert("PathToTabularSection", Undefined);
	
	DescriptionOfColumns.Insert("FormItemName", Undefined);
	DescriptionOfColumns.Insert("FormTableName", Undefined);
	
	Return DescriptionOfColumns;
	
EndFunction

Function AddDescriptionOfAllDestinations(FormTemplate)
	
	Prefix = "AllAssignments";
	
	QueryText = 
	"SELECT
	|	Assignments.Ref AS Purpose
	|FROM
	|	Catalog.Assignments AS Assignments
	|WHERE
	|	NOT Assignments.DeletionMark";
	
	DescriptionOfColumns = ColumnDescriptionTemplate();
	
	DescriptionOfColumns.Prefix               = Prefix;
	DescriptionOfColumns.QueryText          = QueryText;
	
	FormTemplate.ColumnDescriptions.Add(DescriptionOfColumns);
	
	Return DescriptionOfColumns;
	
EndFunction

Function AddDescriptionImplementationData(FormTemplate, Prefix)
	
	Prefix = ?(IsBlankString(Prefix), "ImplementationData", Prefix);
	
	QueryText =
	"SELECT
	|	NestedQuery.Purpose AS Purpose,
	|	SUM(NestedQuery.Count) AS PrefixImplemented
	|FROM
	|	(SELECT
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Purpose AS Purpose,
	|		GoodsTable.Count AS Count
	|	FROM
	|		Document.SaleAdjustment.Goods AS GoodsTable
	|			LEFT JOIN Document.SaleAdjustment AS SaleAdjustment
	|			ON GoodsTable.Ref.PointInTime < SaleAdjustment.PointInTime
	|				AND (SaleAdjustment.Posted)
	|				AND (SaleAdjustment.DocumentBasis = &PrefixImplementationDocument)
	|				AND (NOT SaleAdjustment.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods), VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)))
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Ref.DocumentBasis = &PrefixImplementationDocument
	|		AND NOT GoodsTable.Ref.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods), VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|		AND SaleAdjustment.Ref IS NULL
	|		AND GoodsTable.Products = &ProductPrefix
	|		AND GoodsTable.Characteristic = &PrefixCharacteristic
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Purpose,
	|		GoodsTable.Count
	|	FROM
	|		Document.CustomerInvoice.Goods AS GoodsTable
	|			LEFT JOIN Document.SaleAdjustment AS SaleAdjustment
	|			ON GoodsTable.Ref = SaleAdjustment.DocumentBasis
	|				AND (SaleAdjustment.Posted)
	|				AND (NOT SaleAdjustment.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods), VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)))
	|	WHERE
	|		SaleAdjustment.Ref IS NULL
	|		AND GoodsTable.Ref = &PrefixImplementationDocument
	|		AND GoodsTable.Products = &ProductPrefix
	|		AND GoodsTable.Characteristic = &PrefixCharacteristic
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReturnDocumentItems.Products,
	|		ReturnDocumentItems.Characteristic,
	|		ReturnDocumentItems.Purpose,
	|		-ReturnDocumentItems.Count
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.Goods AS ReturnDocumentItems
	|	WHERE
	|		ReturnDocumentItems.Ref.Posted
	|		AND ReturnDocumentItems.Ref <> &PrefixReturnDocument
	|		AND ReturnDocumentItems.DocumentSalesOfGoodsAndServices = &PrefixImplementationDocument
	|		AND ReturnDocumentItems.Products = &ProductPrefix
	|		AND ReturnDocumentItems.Characteristic = &PrefixCharacteristic
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Purpose,
	|		GoodsTable.Count
	|	FROM
	|		Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Ref.Contract = &ContractPrefix
	|		AND GoodsTable.Products = &ProductPrefix
	|		AND GoodsTable.Characteristic = &PrefixCharacteristic
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Purpose,
	|		-GoodsTable.Count
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Ref <> &PrefixReturnDocument
	|		AND GoodsTable.Ref.Contract = &ContractPrefix
	|		AND GoodsTable.Products = &ProductPrefix
	|		AND GoodsTable.Characteristic = &PrefixCharacteristic) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Purpose
	|
	|HAVING
	|	SUM(NestedQuery.Count) > 0";
	
	Substitutions = New Structure();
	Substitutions.Insert("PrefixImplemented", "Implemented");
	Substitutions.Insert("ProductPrefix", "Products");
	Substitutions.Insert("PrefixCharacteristic", "Characteristic");
	Substitutions.Insert("PrefixImplementationDocument", "DocumentSalesOfGoodsAndServices");
	Substitutions.Insert("PrefixReturnDocument", "DocumentReturnPolicy");
	Substitutions.Insert("ContractPrefix", "Contract");
	ReplacePrefixInColumnNames(QueryText, Prefix, Substitutions);
	
	DataPaths = New Structure();
	
	DataPaths.Insert("DocumentSalesOfGoodsAndServices");
	DataPaths.Insert("Products");
	DataPaths.Insert("Characteristic");
	DataPaths.Insert("DocumentReturnPolicy", "Object.Ref");
	DataPaths.Insert("Contract", "Object.Contract");
	
	Columns = New ValueList();
	Columns.Add("Implemented", NStr("vi = 'Đã giao hàng';
									|ru = 'Реализовано';
									|en = 'Sold'; fa = 'فروخته‌شده';
									|it = 'Venduto';
									|pl = 'Sold';
									|tr = 'Uygulandı'"), True);
	
	DefaultColumns = New Array();
	DefaultColumns.Add("Implemented");
	
	DescriptionOfColumns = ColumnDescriptionTemplate();
	
	DescriptionOfColumns.Prefix               = Prefix;
	DescriptionOfColumns.QueryText          = QueryText;
	DescriptionOfColumns.DataPaths           = DataPaths;
	DescriptionOfColumns.Columns               = Columns;
	DescriptionOfColumns.DefaultColumns    = DefaultColumns;
	DescriptionOfColumns.SpeakersAreNotSwitchedOff  = DefaultColumns;
	
	FormTemplate.ColumnDescriptions.Add(DescriptionOfColumns);
	
	Return DescriptionOfColumns;
	
EndFunction

Function AddDescriptionOfYourOrders(FormTemplate, AddStorno, Prefix, Columns, SelectByWarehouse)
	
	UseGoodsQualityControl = GetFunctionalOption("UseGoodsQualityControl");
	
	QueryTexts = New Array();
	
	QueryText =
		"SELECT ALLOWED
		|	CASE
		|		WHEN CAST(&ProductPrefix AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &PrefixDivision
		|		ELSE &WarehousePrefix
		|	END AS Ref
		|INTO WarehouseParameterOverridable";
	QueryTexts.Add(QueryText);
	
	#Region TempTableInventoryAndNeedsOfLotReferences
	
	Texts = New Array();
	
	If SelectByWarehouse Then
		SelectParameterByWarehouse =
			"SELECT
			|	Filter.Ref AS Warehouse
			|FROM
			|	WarehouseParameterOverridable AS Filter";
		SelectByWarehouseCondition =
			"SELECT TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	WarehouseParameterOverridable AS Filter
			|WHERE
			|	Filter.Ref = Table.Warehouse";
	Else
		SelectParameterByWarehouse = "Warehouse";
		SelectByWarehouseCondition = "TRUE";
	EndIf;
	
	If UseGoodsQualityControl Then
		
		TextOfSet =
			"SELECT
			|	Balance.Purpose AS Purpose,
			|	Balance.OrderDocument AS Lot,
			|	Balance.LockedInStockBalance
			|		- Balance.ReserveAtWarehouseFromLockedBalance
			|		- Balance.ReserveUponReceiptFromLockedBalance AS InStock,
			|	0 AS ReserveAsRequiredUnderOrder,
			|	Balance.LockedInStockBalance
			|		+ Balance.LockedReceiptBalance AS Inventory,
			|	Balance.ReserveAtWarehouseFromLockedBalance
			|		+ Balance.ReserveUponReceiptFromLockedBalance AS PlannedShipment
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|			AND NOT Purpose IN(&PrefixExcludedAssignments)
			|			AND Products = &ProductPrefix
			|			AND Characteristic = &PrefixCharacteristic
			|			AND Warehouse IN(&SelectParameterByWarehouse)) AS Balance";
		Texts.Add(TextOfSet);
		
		If AddStorno Then
			
			TextOfSet =
				"SELECT
				|	Table.Purpose AS Purpose,
				|	Table.OrderDocument AS Lot,
				|	CASE
				|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
				|			THEN - Table.LockedInStock - Table.ReserveAtWarehouseFromLocked
				|		ELSE Table.LockedInStock + Table.ReserveAtWarehouseFromLocked
				|	END AS InStock,
				|	0 AS ReserveAsRequiredUnderOrder,
				|	CASE
				|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
				|			THEN - Table.LockedInStock - Table.LockedReceipt
				|		ELSE Table.LockedInStock + Table.LockedReceipt
				|	END AS Inventory,
				|	CASE
				|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
				|			THEN - Table.ReserveAtWarehouseFromLocked - Table.ReserveUponReceiptFromLocked
				|		ELSE Table.ReserveAtWarehouseFromLocked + Table.ReserveUponReceiptFromLocked
				|	END AS PlannedShipment
				|FROM
				|	AccumulationRegister.InventoryAndDemands AS Table
				|WHERE
				|	Table.Active
				|		AND Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
				|		AND NOT Table.Purpose IN(&PrefixExcludedAssignments)
				|		AND Table.Recorder = &PrefixLogger
				|		AND Table.Products = &ProductPrefix
				|		AND Table.Characteristic = &PrefixCharacteristic
				|		AND TRUE IN (&SelectByWarehouseCondition)
				|	
				|	UNION ALL
				|
				|	SELECT
				|		Table.Purpose AS Purpose,
				|		Table.ReceiptOrder AS Lot,
				|		0 InStock,
				|		Table.Count AS ReserveAsRequiredUnderOrder,
				|		0 AS Inventory,
				|		0 AS PlannedShipment
				|	FROM
				|		InformationRegister.InventoryAllocation AS Table
				|	WHERE
				|		Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
				|			AND NOT Table.Purpose IN(&PrefixExcludedAssignments)
				|			AND Table.ShipmentOrder = &PrefixLogger
				|			AND Table.Products = &ProductPrefix
				|			AND Table.Characteristic = &PrefixCharacteristic
				|			AND TRUE IN(&SelectByWarehouseCondition)
				|			AND Table.InventoryState IN(
				|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
				|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
				|			AND Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)";
			Texts.Add(TextOfSet);
			
		EndIf;
		
		TextOfSet = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
		QueryText =
			"SELECT ALLOWED
			|	Set.Purpose AS Purpose,
			|	Set.Lot AS Lot,
			|	SUM(
			|		CASE
			|			WHEN Set.InStock > 0
			|				THEN Set.InStock
			|			ELSE 0
			|		END
			|		+ Set.ReserveAsRequiredUnderOrder) AS InStock,
			|	SUM(
			|		CASE
			|			WHEN Set.Inventory > Set.PlannedShipment
			|				THEN Set.Inventory
			|			ELSE Set.PlannedShipment
			|		END) AS Allocated,
			|	SUM(
			|		CASE
			|			WHEN Set.Inventory > Set.PlannedShipment
			|				THEN 0
			|			ELSE Set.PlannedShipment - Set.Inventory
			|		END) AS UnfundedNeed,
			|	SUM(Set.PlannedShipment) AS PlannedShipment
			|INTO TempTableInventoryAndNeedsOfLotReferencesOverridable
			|FROM
			|	&Set AS Set
			|GROUP BY
			|	Set.Purpose,
			|	Set.Lot
			|INDEX BY
			|	Purpose, Lot";
		
		QueryText = StrReplace(QueryText, "&Set", StrTemplate("(%1)", TextOfSet));
		QueryTexts.Add(QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region TempTableInventoryAndNeeds
	
	Texts = New Array();
	
	TextOfSet =
		"SELECT
		|	Balance.Purpose AS Purpose,
		|	Balance.InStockBalance
		|		- Balance.LockedInStockBalance
		|		- Balance.ReserveAtWarehouseBalance
		|		- Balance.ReserveAsReceivedBalance InStock,
		|	0 AS AvailableFromLotReferences,
		|	0 AvailableFromLotReferenceOfDocumentLine,
		|	0 AS ReserveAsRequiredUnderOrder,
		|	Balance.ReserveAtWarehouseBalance
		|		+ Balance.ReserveAsReceivedBalance
		|		+ Balance.SnoozeReservationBalance
		|		+ Balance.ToSupplyBalance
		|		- Balance.InStockBalance
		|		- Balance.OrderedBalance AS UnfundedNeed,
		|	0 AS UnsecuredNeedFromLotReferenceLineOfDocument,
		|	Balance.ReserveAtWarehouseBalance
		|		+ Balance.ReserveAsReceivedBalance
		|		+ Balance.SnoozeReservationBalance
		|		+ Balance.ToSupplyBalance AS PlannedShipment
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND NOT Purpose IN(&PrefixExcludedAssignments)
		|			AND Products = &ProductPrefix
		|			AND Characteristic = &PrefixCharacteristic
		|			AND Warehouse IN(&SelectParameterByWarehouse)) AS Balance";
	Texts.Add(TextOfSet);
		
	If AddStorno Then
		
		TextOfSet =
			"SELECT
			|	Table.Purpose AS Purpose,
			|	CASE
			|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN
			|				- Table.InStock
			|					- Table.LockedInStock
			|					- Table.ReserveAtWarehouse
			|		ELSE
			|			Table.InStock
			|				+ Table.LockedInStock
			|				+ Table.ReserveAtWarehouse
			|	END AS InStock,
			|	0 AS AvailableFromLotReferences,
			|	0 AvailableFromLotReferenceOfDocumentLine,
			|	0 AS ReserveAsRequiredUnderOrder,
			|	CASE
			|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN
			|				- Table.ReserveAtWarehouse
			|					- Table.ReserveAsReceived
			|					- Table.SnoozeReservation
			|					- Table.ToSupply
			|					+ Table.InStock
			|					+ Table.Ordered
			|		ELSE
			|			Table.ReserveAtWarehouse
			|				+ Table.ReserveAsReceived
			|				+ Table.SnoozeReservation
			|				+ Table.ToSupply
			|				- Table.InStock
			|				- Table.Ordered
			|	END AS UnfundedNeed,
			|	0 AS UnsecuredNeedFromLotReferenceLineOfDocument,
			|	CASE
			|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN
			|				- Table.ReserveAtWarehouse
			|					- Table.ReserveAsReceived
			|					- Table.SnoozeReservation
			|					- Table.ToSupply
			|		ELSE
			|			Table.ReserveAtWarehouse
			|				+ Table.ReserveAsReceived
			|				+ Table.SnoozeReservation
			|				+ Table.ToSupply
			|	END AS PlannedShipment
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS Table
			|WHERE
			|	Table.Active
			|		AND Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|		AND NOT Table.Purpose IN(&PrefixExcludedAssignments)
			|		AND Table.Recorder = &PrefixLogger
			|		AND Table.Products = &ProductPrefix
			|		AND Table.Characteristic = &PrefixCharacteristic
			|		AND TRUE IN(&SelectByWarehouseCondition)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Table.Purpose AS Purpose,
			|		0 InStock,
			|		0 AS AvailableFromLotReferences,
			|		0 AvailableFromLotReferenceOfDocumentLine,
			|		Table.Count AS ReserveAsRequiredUnderOrder,
			|		0 AS UnfundedNeed,
			|		0 AS UnsecuredNeedFromLotReferenceLineOfDocument,
			|		0 AS PlannedShipment
			|	FROM
			|		InformationRegister.InventoryAllocation AS Table
			|	WHERE
			|		Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|			AND NOT Table.Purpose IN(&PrefixExcludedAssignments)
			|			AND Table.ShipmentOrder = &PrefixLogger
			|			AND Table.Products = &ProductPrefix
			|			AND Table.Characteristic = &PrefixCharacteristic
			|			AND TRUE IN(&SelectByWarehouseCondition)
			|			AND Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
			|			AND Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)";
		Texts.Add(TextOfSet);
		
	EndIf;
	
	If UseGoodsQualityControl Then
		
		TextOfSet =
			"SELECT
			|	Lots.Purpose AS Purpose,
			|	0 AS InStock,
			|	Lots.InStock AS AvailableFromLotReferences,
			|	CASE
			|		WHEN &PrefixControlledLotReference = Lots.Lot
			|			THEN Lots.InStock
			|		ELSE 0
			|	END AS AvailableFromLotReferenceOfDocumentLine,
			|	0 AS ReserveAsRequiredUnderOrder,
			|	Lots.Allocated AS UnfundedNeed,
			|	CASE
			|		WHEN &PrefixControlledLotReference = Lots.Lot
			|			THEN Lots.UnfundedNeed
			|		ELSE 0
			|	END AS UnsecuredNeedFromLotReferenceLineOfDocument,
			|	Lots.PlannedShipment AS PlannedShipment
			|FROM
			|	TempTableInventoryAndNeedsOfLotReferencesOverridable AS Lots";
		Texts.Add(TextOfSet);
		
	EndIf;
	
	// The need for materials and semi-finished products according to the production schedule.
	If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		TextOfSet =
			"SELECT
			|	Table.Purpose AS Purpose,
			|	0 AS InStock,
			|	0 AS AvailableFromLotReferences,
			|	0 AS AvailableFromLotReferenceOfDocumentLine,
			|	0 AS ReserveAsRequiredUnderOrder,
			|	Table.ToSupply AS UnfundedNeed,
			|	0 AS UnsecuredNeedFromLotReferenceLineOfDocument,
			|	Table.ToSupply AS PlannedShipment
			|FROM
			|	InformationRegister.OrderStructure AS Table
			|WHERE
			|	Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|		AND NOT Table.Purpose IN(&PrefixExcludedAssignments)
			|		AND Table.Products = &ProductPrefix
			|		AND Table.Characteristic = &PrefixCharacteristic
			|		AND TRUE IN (&SelectByWarehouseCondition)
			|		AND Table.Warehouse = &WarehousePrefix
			|		AND Table.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)";
		Texts.Add(TextOfSet);
		
	EndIf;
	
	// If the appointment is selected in a document that intercepts the supply from the order to itself,
	// then this block is added.
	TextOfSet =
		"SELECT
		|	Inventories.Purpose AS Purpose,
		|	0 AS InStock,
		|	0 AS AvailableFromLotReferences,
		|	0 AS AvailableFromLotReferenceOfDocumentLine,
		|	0 AS ReserveAsRequiredUnderOrder,
		|	Inventories.OrderedBalance AS UnfundedNeed,
		|	0 AS UnsecuredNeedFromLotReferenceLineOfDocument,
		|	0 AS PlannedShipment
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|		AND NOT Purpose IN(&PrefixExcludedAssignments)
		|			AND OrderDocument = &OrderPrefix
		|			AND Products = &ProductPrefix
		|			AND Characteristic = &PrefixCharacteristic
		|			AND Warehouse IN(&SelectParameterByWarehouse)) AS Inventories";
	Texts.Add(TextOfSet);
	
	TextOfSet = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
		"SELECT
		|	Set.Purpose AS Purpose,
		|	SUM(
		|		CASE
		|			WHEN Set.InStock > 0
		|				THEN Set.InStock
		|			ELSE 0
		|		END
		|		+ Set.ReserveAsRequiredUnderOrder) AS InStock,
		|	SUM(
		|		CASE
		|			WHEN Set.InStock + Set.AvailableFromLotReferences > 0
		|				THEN Set.InStock + Set.AvailableFromLotReferences
		|			ELSE 0
		|		END
		|		+ Set.ReserveAsRequiredUnderOrder) AS AvailableForReservation,
		|	SUM(Set.AvailableFromLotReferenceOfDocumentLine) AS AvailableFromLotReferenceOfDocumentLine,
		|	SUM(Set.UnfundedNeed) AS UnfundedNeed,
		|	SUM(Set.UnsecuredNeedFromLotReferenceLineOfDocument) AS UnsecuredNeedFromLotReferenceLineOfDocument,
		|	SUM(Set.PlannedShipment) AS PlannedShipment
		|INTO TempTableInventoryAndNeedsOverridable
		|FROM
		|	&Set AS Set
		|GROUP BY
		|	Set.Purpose
		|INDEX BY
		|	Purpose";
		
	QueryText = StrReplace(QueryText, "&Set", StrTemplate("(%1)", TextOfSet));
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	TemporaryTable = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	TemporaryTable = StrReplace(TemporaryTable, "&SelectParameterByWarehouse", SelectParameterByWarehouse);
	TemporaryTable = StrReplace(TemporaryTable, "&SelectByWarehouseCondition", SelectByWarehouseCondition);
	
	QueryText =
		"SELECT
		|	Set.Purpose AS Purpose,
		|	&SelectionFieldsPreceding,
		|
			// Available for shipment.
		|	CASE
				// The document does not support shipment of items under control (the Lot reference is not defined),
				// or the checked item is shipped in the current line of the document (the Lot reference is empty).
		|		WHEN
		|			&PrefixControlledLotReference IN(
		|				UNDEFINED,
		|				VALUE(Catalog.ControlledLots.EmptyRef))
					// Free Balance for shipment of items that have passed inspection.
		|			THEN
		|				Set.InStock
					// In the current line of the document, the item of a specific batch is shipped under control (the batch is full),
		|		ELSE Set.AvailableFromLotReferenceOfDocumentLine
		|	END AS PrefixInStock,
		|
			// Available for reservation.
		|	CASE
				// The document does not support shipment of items under control (the Lot reference is not defined),
				// or the item is reserved in the current line of the document without specifying the Lot reference under control (the Lot reference is empty).
		|		WHEN
		|			&PrefixControlledLotReference IN(
		|				UNDEFINED,
		|				VALUE(Catalog.ControlledLots.EmptyRef))
					// Free Balance for shipment of items that have passed inspection.
		|			THEN
		|				Set.AvailableForReservation
					// In the current line of the document, reserve the item of a specific Lot reference for control (the Lot reference is full),
		|		ELSE Set.AvailableFromLotReferenceOfDocumentLine
		|	END AS PrefixIsAvailableForReservation,
		|
			// Unsecured need/surplus in verified goods.
		|	Set.UnfundedNeed
		|	+ CASE
				// The document does not support supplying items with inspection (the Lot reference is not defined),
				// or the current line of the document provides without inspection
				// (the Lot reference is not empty, but the inspection flag is disabled).
		|		WHEN
		|			&PrefixControlledLotReference IN(
		|					UNDEFINED,
		|					VALUE(Catalog.ControlledLots.EmptyRef))
		|				OR &PrefixCheckQuality IN (UNDEFINED, FALSE)
		|			THEN 0
					// The current line of the document provides goods with the control of a specific Lot reference.
		|		ELSE Set.UnsecuredNeedFromLotReferenceLineOfDocument
		|	END AS PrefixNeed,
		|	
		|	Set.PlannedShipment AS ArchivePrefix
		|	,&SelectionFieldsAreSubsequent
		|FROM
		|	TempTableInventoryAndNeedsOverridable AS Set
		|WHERE
		|	&CurrencyPrefix = UNDEFINED
		|		OR CAST(Set.Purpose AS Catalog.Assignments).AssignmentType <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
		|		OR CAST(Set.Purpose AS Catalog.Assignments).Contract.ARAPCurrency = &CurrencyPrefix";
	
	Substitutions = New Structure();
	Substitutions.Insert("PrefixNeed", "Demand");
	Substitutions.Insert("ArchivePrefix", "Archive_");
	Substitutions.Insert("PrefixInStock", "InStock");
	Substitutions.Insert("ProductPrefix", "Products");
	Substitutions.Insert("PrefixCharacteristic", "Characteristic");
	Substitutions.Insert("WarehousePrefix", "Warehouse");
	Substitutions.Insert("PrefixDivision", "Department");
	Substitutions.Insert("PrefixLogger", "Recorder");
	Substitutions.Insert("OrderPrefix", "ReferenceOrder");
	Substitutions.Insert("PrefixExcludedAssignments", "ExcludedAssignments");
	Substitutions.Insert("PrefixControlledLotReference", "ControlledLotReference");
	Substitutions.Insert("PrefixCheckQuality", "ToControlQuality");
	Substitutions.Insert("CurrencyPrefix", "Currency");
	Substitutions.Insert("WarehouseParameterOverridable", "WarehouseParameter");
	Substitutions.Insert("TempTableInventoryAndNeedsOfLotReferencesOverridable", "TempTableInventoryAndNeedsOfLotReferences");
	Substitutions.Insert("TempTableInventoryAndNeedsOverridable", "TempTableInventoryAndNeeds");
	
	ReplacePrefixInColumnNames(QueryText, Prefix, Substitutions);
	ReplacePrefixInColumnNames(TemporaryTable, Prefix, Substitutions);
	
	DataPaths = New Structure();
	
	DataPaths.Insert("Products");
	DataPaths.Insert("Characteristic");
	DataPaths.Insert("Warehouse");
	DataPaths.Insert("Department");
	DataPaths.Insert("ReferenceOrder");
	DataPaths.Insert("ExcludedAssignments");
	DataPaths.Insert("ControlledLotReference");
	DataPaths.Insert("ToControlQuality");
	DataPaths.Insert("Currency");
	
	If AddStorno Then
		DataPaths.Insert("Recorder", "Object.Ref");
	EndIf;
	
	DefaultColumns = New Array();
	DefaultColumns.Add("Demand");
	
	DescriptionOfColumns = ColumnDescriptionTemplate();
	
	DescriptionOfColumns.Prefix = Prefix;
	DescriptionOfColumns.TemporaryTable = TemporaryTable;
	DescriptionOfColumns.QueryText = QueryText;
	DescriptionOfColumns.DataPaths = DataPaths;
	DescriptionOfColumns.Columns = Columns;
	DescriptionOfColumns.DefaultColumns = DefaultColumns;
	
	FormTemplate.ColumnDescriptions.Add(DescriptionOfColumns);
	
	Return DescriptionOfColumns;
	
EndFunction

Procedure ReplacePrefixInColumnNames(QueryText, Prefix, Names)
	
	For Each Name In Names Do
		QueryText = StrReplace(QueryText, Name.Key, Prefix + "_" + Name.Value);
	EndDo;
	
EndProcedure

Function DestinationField_(Items, PathToTheDestinationField)
	
	Text = StrReplace(PathToTheDestinationField, "Object.", "");
	Paths = StrSplit(Text, ".");
	TagName = StrConcat(Paths);
	Item = Items[TagName];
	Return Item;
	
EndFunction

Function FormTable(Items, PathToTheDestinationField)
	
	Text = StrReplace(PathToTheDestinationField, "Object.", "");
	Paths = StrSplit(Text, ".");
	Item = Undefined;
	If Paths.Count() = 2 Then
		Item = Items[Paths[0]];
	ElsIf Paths.Count() = 3 Then // EditingStages
		Item = Items[Paths[0] + Paths[1]];
	EndIf;
	Return Item;
	
EndFunction

// Converts an incoming parameter, for example:
//  Object.Warehouse - > Object.Warehouse
//  An object.Goods.Item - > Items.Goods.Current data.Nomenclature
//
Function GenerateDataPath(FullPath, PathToTheDestinationField, FormTable, PathToTabularSection)
	
	DesiredPointByCount = 1;
	PathToObject = Left(PathToTheDestinationField, Max(StrFind(PathToTheDestinationField, ".", , , DesiredPointByCount) - 1, 0));
	DesiredPointByCount = 2;
	PathToTop = Left(PathToTheDestinationField, Max(StrFind(PathToTheDestinationField, ".", , , DesiredPointByCount) - 1, 0));
	
	OnePointIsAllowed = ?(PathToObject = "", False, StrFind(FullPath, PathToObject) > 0);
	TwoPointsAreAllowed = ?(PathToTop = "", False, StrFind(FullPath, PathToTop) > 0);
	
	If Not ValueIsFilled(PathToTheDestinationField) Then
		OnePointIsAllowed = 1;
	EndIf;
	
	AllowedNumberOfPoints = ?(TwoPointsAreAllowed, 2, ?(OnePointIsAllowed, 1, 0));
	
	ThisIsReferringToTabularPart = AllowedNumberOfPoints = 2;
	
	If Not ThisIsReferringToTabularPart And PathToTabularSection <> Undefined
				And Left(FullPath, StrLen(PathToTabularSection)) = PathToTabularSection Then
		
		ThisIsReferringToTabularPart = True;
		AllowedNumberOfPoints = StrSplit(PathToTabularSection, ".").Count();
		PathToTop = PathToTabularSection;
		
	EndIf;
	ExpressingObjectWithoutInversion = PageSplitByPointOfCirculationOfCIB(FullPath, AllowedNumberOfPoints).DataPath;
	
	If ThisIsReferringToTabularPart Then
		
		DataPath = StrReplace(ExpressingObjectWithoutInversion, PathToTop,
			"Items." + FormTable.Name + ".CurrentData");
		
	Else
		
		DataPath = ExpressingObjectWithoutInversion;
		
	EndIf;
	
	Return DataPath;
	
EndFunction

Function ExpressionsOfPathsToTermsOfUseData(TermsOfUse_)
	
	ThereIsSpecialSymbol = StrFind(TermsOfUse_, "&") <> 0;
	
	SubstringsOfExpressions = ?(ThereIsSpecialSymbol,
		StrSplit(TermsOfUse_, "&", False),
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(TermsOfUse_, "Object.", True));
	
	Array = New Array();
	
	For Each String In SubstringsOfExpressions Do
		
		If Not ThereIsSpecialSymbol Then
			String = "Object." + String;
		EndIf;
		
		Array.Add(Mid(String, 1, StrFind(String, " ") - 1));
		
	EndDo;
	
	Return Array;
	
EndFunction

Function AddDescriptionOfMaterialsAndWorkInProduction(FormTemplate, AddStorno, Prefix)
	
	Prefix = ?(IsBlankString(Prefix), "MaterialsAndWorksInProduction", Prefix);
	
	QueryText = 
	"// Request for the ""Add description of materials and work in production"" Prefix method
	|// 
	|
	|SELECT
	|	TableBalance.Purpose        AS Purpose,
	|	&SelectionFieldsPreceding,
	|	TableBalance.CountBalance AS PrefixQuantity
	|	,&SelectionFieldsAreSubsequent
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.Balance(,
	|		Purpose       <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND Organization    = &PrefixOrganization
	|		AND Products   = &ProductPrefix
	|		{Department   = &PrefixDivision}
	|		{Characteristic  = &PrefixCharacteristic}) AS TableBalance";
	
	If AddStorno Then
		QueryText = QueryText
		+ TMCommonUse.QuerySeparatorInJoin()
		+ "SELECT
		|	TableStorno.Purpose       AS Purpose,
		|	&SelectionFieldsPreceding,
		|	TableStorno.CountTurnover AS PrefixQuantity
		|	,&SelectionFieldsAreSubsequent
		|FROM
		|	AccumulationRegister.MaterialsAndWorksInProduction.Turnovers(, , Recorder,
		|		Purpose       <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND Organization    = &PrefixOrganization
		|		AND Products   = &ProductPrefix
		|		{Department  = &PrefixDivision}
		|		{Characteristic = &PrefixCharacteristic}
		|		) AS TableStorno
		|WHERE
		|	TableStorno.Recorder = &PrefixLogger";
	EndIf;
	
	QueryText = StrReplace(QueryText, "Prefix", Prefix + "_");
	
	DataPaths = New Structure();
	
	DataPaths.Insert("Products");
	DataPaths.Insert("Characteristic");
	DataPaths.Insert("Department");
	DataPaths.Insert("Organization");
	
	If AddStorno Then
		DataPaths.Insert("Recorder", "Object.Ref");
	EndIf;
	
	// Forming a list of columns that can be displayed in the list of assignments
	
	Columns = New ValueList();
	Columns.Add("Count", NStr("vi = 'Số lượng sản xuất';
								|ru = 'Количество в производстве';
								|en = 'Quantity in production'; fa = 'Quantity in production';
								|it = 'Quantità in produzione';
								|pl = 'Ilość w produkcji';
								|tr = 'Üretimdeki miktar'"), False);
	
	DefaultColumns = New Array();
	DefaultColumns.Add("Count");
	
	DescriptionOfColumns = ColumnDescriptionTemplate();
	
	DescriptionOfColumns.Prefix               = Prefix;
	DescriptionOfColumns.QueryText          = QueryText;
	DescriptionOfColumns.DataPaths           = DataPaths;
	DescriptionOfColumns.Columns               = Columns;
	DescriptionOfColumns.DefaultColumns    = DefaultColumns;
	
	FormTemplate.ColumnDescriptions.Add(DescriptionOfColumns);
	
	Return DescriptionOfColumns;
	
EndFunction


Function AddDescriptionOfProductsSentToKeepers(FormTemplate, AddStorno, Prefix)
	
	Prefix = ?(IsBlankString(Prefix), "GoodsTransferredToCustodians", Prefix);
	
	TemporaryTable =
	"SELECT
	|	Keys.DimensionKey AS Ref
	|INTO ItemAccountingAnalyticsPrefix
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS Keys
	|WHERE
	|	NOT Keys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND Keys.Products = &ProductPrefix
	|		AND Keys.Characteristic = &PrefixCharacteristic
	|		AND Keys.StorageLocation = &ContractPrefix
	|INDEX BY
	|	Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableBalance.CountBalance AS CountBalance
	|INTO PrefixGoodsOfOrganizationsBalances
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(,
	|		Organization = &PrefixOrganization
	|			AND ItemsLocationAttributes IN(
	|				SELECT
	|					Analysts.Ref AS Ref
	|				FROM
	|					ItemAccountingAnalyticsPrefix AS Analysts)) AS TableBalance
	|INDEX BY
	|	ItemsLocationAttributes";
	
	QueryText = 
	"// Request for the ""Add a description to the stored"" Prefix method
	|// 
	|
	|SELECT
	|	TableBalance.ItemsLocationAttributes.Purpose AS Purpose,
	|	&SelectionFieldsPreceding,
	|	TableBalance.CountBalance AS PrefixPassed
	|	,&SelectionFieldsAreSubsequent
	|FROM
	|	PrefixGoodsOfOrganizationsBalances AS TableBalance
	|";
	
	If AddStorno Then
		QueryText = QueryText
		+ TMCommonUse.QuerySeparatorInJoin()
		+ "SELECT
		|	TableStorno.ItemsLocationAttributes.Purpose AS Purpose,
		|	&SelectionFieldsPreceding,
		|	CASE
		|		WHEN TableStorno.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -TableStorno.Count
		|		ELSE TableStorno.Count
		|	END AS PrefixPassed
		|	,&SelectionFieldsAreSubsequent
		|FROM
		|	AccumulationRegister.CompanyGoods AS TableStorno
		|WHERE
		|	TableStorno.Recorder = &PrefixLogger
		|	AND TableStorno.Organization = &PrefixOrganization
		|	AND TableStorno.ItemsLocationAttributes IN(
		|		SELECT
		|			Analysts.Ref AS Ref
		|		FROM
		|			ItemAccountingAnalyticsPrefix AS Analysts
		|		)
		|";
	EndIf;
	
	Substitutions = New Structure();
	Substitutions.Insert("PrefixPassed",        "Passed");
	Substitutions.Insert("PrefixOrganization",     "Organization");
	Substitutions.Insert("ProductPrefix",    "Products");
	Substitutions.Insert("PrefixCharacteristic",  "Characteristic");
	Substitutions.Insert("ContractPrefix",         "Contract");
	Substitutions.Insert("ItemAccountingAnalyticsPrefix", "ProductAccountingAnalysts");
	Substitutions.Insert("PrefixGoodsOfOrganizationsBalances",   "CompanyGoodsBalance");
	If AddStorno Then
		Substitutions.Insert("PrefixLogger", "Recorder");
	EndIf;
	
	ReplacePrefixInColumnNames(QueryText, Prefix, Substitutions);
	ReplacePrefixInColumnNames(TemporaryTable, Prefix, Substitutions);
	
	DataPaths = New Structure();
	
	DataPaths.Insert("Organization");
	DataPaths.Insert("Contract");
	DataPaths.Insert("Products");
	DataPaths.Insert("Characteristic");
	
	If AddStorno Then
		DataPaths.Insert("Recorder", "Object.Ref");
	EndIf;
	
	// Forming a list of columns that can be displayed in the list of assignments
	
	Columns = New ValueList();
	Columns.Add("Passed", NStr("vi = 'Đã chuyển giao';
								|ru = 'Передано';
								|en = 'Handed over'; fa = 'تحویل‌شده';
								|it = 'Consegnato';
								|pl = 'Handed over';
								|tr = 'Teslim edilenler'"), False);
	
	DefaultColumns = New Array();
	DefaultColumns.Add("Passed");
	
	DescriptionOfColumns = ColumnDescriptionTemplate();
	
	DescriptionOfColumns.Prefix              = Prefix;
	DescriptionOfColumns.QueryText         = QueryText;
	DescriptionOfColumns.TemporaryTable     = TemporaryTable;
	DescriptionOfColumns.DataPaths          = DataPaths;
	DescriptionOfColumns.Columns              = Columns;
	DescriptionOfColumns.DefaultColumns   = DefaultColumns;
	
	FormTemplate.ColumnDescriptions.Add(DescriptionOfColumns);
	
	Return DescriptionOfColumns;
	
EndFunction

Function GenerateQueryTextSelectionData(AssignmentFormTemplate, QueryOptions)
	
	TermsOfAppointment = New Array();
	ExcludeRefAssignment = AssignmentFormTemplate.AssignmentTemplates.Count() = 0;
	For Each DestinationPattern In AssignmentFormTemplate.AssignmentTemplates Do
		
		IncludeInFinalQuery = CheckUsageConditions("",
			DestinationPattern.TermsOfUse_,
			QueryOptions,
			DestinationPattern.PathToTheDestinationField);
		
		If Not IncludeInFinalQuery Then
			Continue;
		EndIf;
		
		ExcludeRefAssignment = ExcludeRefAssignment Or DestinationPattern.ExcludeRefAssignment;
		For Each FilterField In DestinationPattern Do
			
			If ValueIsFilled(FilterField.Value)
				And FilterField.Key <> "TermsOfUse_"
				And FilterField.Key <> "VisibleSelectionsOnForm"
				And FilterField.Key <> "ExcludeRefAssignment"
				And FilterField.Key <> "AssignmentTypes"
				And FilterField.Key <> "PathToTheDestinationField" Then
				
				If FilterField.Key = "LineOfBusiness"
					And (StrFind(FilterField.Value, "Object.") <> 0
						Or StrFind(FilterField.Value, "&") <> 0) Then
					
					If Not QueryOptions.Property("LineOfBusiness") 
						Or Not LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(QueryOptions.LineOfBusiness) Then
						Continue;
					EndIf;
					
				EndIf;
				
				If StrFind(FilterField.Value, "Object.") <> 0 Then
					Condition = "Assignments." + FilterField.Key + " = " + "&" + FilterField.Key;
				ElsIf StrFind(FilterField.Value, "&") <> 0 Then
					Condition = "Assignments." + FilterField.Key + " IN( " + FilterField.Value + ")";
				Else
					Condition = "Assignments." + FilterField.Key + " = (" + FilterField.Value + ")";
				EndIf;
				TermsOfAppointment.Add(Condition);
				
			EndIf;
			
		EndDo;
	EndDo;
	
	If ExcludeRefAssignment Then
		TermsOfAppointment.Add("Assignments.OrderDocument <> &Source");
	EndIf;
	AddPartnerExclusionCondition(TermsOfAppointment, "Assignments");
	
	TermsOfAppointment.Add("Assignments.AssignmentType IN (&AssignmentTypes)");
	QueryTextWhere = ?(TermsOfAppointment.Count() > 0,
		StrConcat(TermsOfAppointment, Chars.LF + "	And "), "TRUE");
		
	QueryText = 
	"SELECT TOP 50
	|	Assignments.Ref AS Purpose
	|FROM
	|	Catalog.Assignments AS Assignments
	|WHERE
	|	NOT Assignments.DeletionMark
	|		AND Assignments.Description LIKE &SearchString
	|		AND &Conditions";
	
	QueryText = StrReplace(QueryText, "&Conditions", QueryTextWhere);
	
	Return QueryText;
	
EndFunction

Procedure FillInParameterValueFromIB(SourceOfParametersObtainedFromInformationSecurity, SourceOfParameters)
	
	For Each Item In SourceOfParametersObtainedFromInformationSecurity Do
		
		AttributeValue = Common.ObjectAttributesValues(
			SourceOfParameters[Item.Value.ParameterName],
			Item.Value.Appeal);
		
		Item.Value.Value = AttributeValue[Item.Value.Appeal];
		
	EndDo;
	
EndProcedure

Procedure SourceOfParametersObtainedFromInformationSecurity(Prefix, Expression, PathToTheDestinationField, Result)
	
	// The input receives an expression, for example, "Object.Products.Nomenclature.Nomenclature types <> ..."
	// or "Props processing.Products.Nomenclature.Nomenclature type <> ...".
	// or "Table.Nomenclature.The Nomenclature type <>...".
	// Also comes the path to the Destination field.
	// For example: "Object.Products.Assignment"
	// or "Props processing.Products.Appointment".
	// or "Table.Appointment".
	// If the expression refers to form fields that are not related to the Destination field or the destination field is not nested anywhere, for example, "Destination",
	// then you must always specify a special character at the beginning of the data access,
	// for example: "&Nomenclature.Nomenclature types <> ... And &Object.Products.Nomenclature.Nomenclature type <> ..."
	// there must be a space after accessing the data, for example incorrectly: "Object.Products.Nomenclature.Nomenclature types<>..."
	
	DesiredPointByCount = 1;
	PathToObject = Left(PathToTheDestinationField, Max(StrFind(PathToTheDestinationField, ".", , , DesiredPointByCount) - 1, 0));
	DesiredPointByCount = 2;
	PathToTop = Left(PathToTheDestinationField, Max(StrFind(PathToTheDestinationField, ".", , , DesiredPointByCount) - 1, 0));
	
	DataPathSeparator = "";
	If StrFind(Expression, "&") <> 0 Then
		DataPathSeparator = "&";
	Else
		DesiredPointByCount = 1;
		DataPathSeparator = Left(PathToTheDestinationField, Max(StrFind(PathToTheDestinationField, ".", , , DesiredPointByCount), 0));
	EndIf;
	
	If Expression = "" Then
		SubstringsOfExpressions = New Array();
	Else
		SubstringsOfExpressions = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Expression, DataPathSeparator, True);
	EndIf;
	
	For Each SubstringOfExpression In SubstringsOfExpressions Do
		
		If DataPathSeparator <> "&" Then
			SubstringOfExpression = DataPathSeparator + SubstringOfExpression;
		EndIf;
		
		FullPath = Mid(SubstringOfExpression, 1, StrFind(SubstringOfExpression, " ") - 1);
		
		OnePointIsAllowed = ?(PathToObject = "", False, StrFind(FullPath, PathToObject) > 0);
		TwoPointsAreAllowed = ?(PathToTop = "", False, StrFind(FullPath, PathToTop) > 0);
		
		AllowedNumberOfPoints = ?(TwoPointsAreAllowed, 2, ?(OnePointIsAllowed, 1, 0));
		PartitioningResult = PageSplitByPointOfCirculationOfCIB(FullPath, AllowedNumberOfPoints);
		
		If PartitioningResult.Appeal <> "" Then
			
			BeginningOfLastWord = StrFind(FullPath, ".", SearchDirection.FromEnd);
			LastWord = Mid(FullPath, BeginningOfLastWord + 1);
			
			LeftSideOfParameterName = ?(ValueIsFilled(Prefix), Prefix + "_", "");
			NameOfParameterWithAccess = LeftSideOfParameterName + LastWord;
			NameOfParameterWithAccess = TrimAll(NameOfParameterWithAccess);
			
			FullPath = PartitioningResult.DataPath;
			
			BeginningOfLastWord = StrFind(FullPath, ".", SearchDirection.FromEnd);
			LastWord = Mid(FullPath, BeginningOfLastWord + 1);
			ParameterName = LeftSideOfParameterName + LastWord;
			ParameterName = TrimAll(ParameterName);
			
			ParametersForGettingValue = New Structure("ParameterName, Appeal, Value", ParameterName, PartitioningResult.Appeal);
			Result.Insert(NameOfParameterWithAccess, ParametersForGettingValue);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function PageSplitByPointOfCirculationOfCIB(DataPath, AllowedNumberOfPoints)
	
	PartitioningResult = New Structure("DataPath, Appeal", "", "");
	
	// The path to the data needs to be cut off so that it does not get access through the point from the data to the IB.
	NumberOfPointOfContactCIB = AllowedNumberOfPoints + 1;
	NumberOfAccessPointSymbol = StrFind(DataPath, ".", , , NumberOfPointOfContactCIB);
	
	If NumberOfAccessPointSymbol > 0 Then
		
		PartitioningResult.DataPath  = Left(DataPath, NumberOfAccessPointSymbol - 1);
		PartitioningResult.Appeal = Right(DataPath, StrLen(DataPath) - NumberOfAccessPointSymbol);
		
	Else
		
		PartitioningResult.DataPath = DataPath;
		
	EndIf;
	
	Return PartitioningResult;
	
EndFunction

#EndRegion

#Region CreatingAppointments

Function MessageNoDestinationInDatabase(DestinationPattern)
	
	Message = Undefined;
	If ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		Message = StrTemplate(NStr("vi = 'Không có nhiệm vụ nào được tìm thấy trong cơ sở dữ liệu thông tin cho hướng giao dịch: ""%1""';
									|ru = 'В информационной базе не обнаружено назначение для направления деятельности: ""%1""';
									|en = 'Assignment for line of business ""%1"" was not found in the infobase'; fa = 'Assignment for line of business ""%1"" was not found in the infobase';
									|it = 'Nel database informatico non è stata trovata l''assegnazione per il settore delle attività: ""%1""';
									|pl = 'W bazie informacyjnej nie znaleziono przeznaczenia dla kierunku działalności: ""%1""';
									|tr = 'Bilgi tabanında iş kolu için atama bulunamadı: ""%1""'"),
			DestinationPattern.LineOfBusiness);
		
	ElsIf ValueIsFilled(DestinationPattern.Contract) Then
		
		Message = StrTemplate(NStr("vi = 'Nhiệm vụ cho hợp đồng không được tìm thấy trong CSTT: ""%1""';
									|ru = 'В информационной базе не обнаружено назначение для договора: ""%1""';
									|en = 'Assignment for contract ""%1"" was not found in the infobase'; fa = 'Assignment for contract ""%1"" was not found in the infobase';
									|it = 'Nel database informatico non è stata trovata l''assegnazione per l''accordo: ""%1""';
									|pl = 'W bazie informacyjnej nie znaleziono przeznaczenia dla umowy: ""%1""';
									|tr = 'Bilgi tabanında sözleşme için atama bulunamadı: ""%1""'"),
			DestinationPattern.Contract);
		
	ElsIf ValueIsFilled(DestinationPattern.Partner) Then
		
		Message = StrTemplate(NStr("vi = 'Không tìm thấy phân công đối tác trong CSTT: ""%1""';
									|ru = 'В информационной базе не обнаружено назначение для партнера: ""%1""';
									|en = 'Assignment for partner ""%1"" was not found in the infobase'; fa = 'Assignment for partner ""%1"" was not found in the infobase';
									|it = 'Nel database informatico non è stata trovata l''assegnazione per il partner: ""%1""';
									|pl = 'W bazie informacyjnej nie znaleziono przeznaczenia dla partnera: ""%1""';
									|tr = 'Bilgi tabanında iş ortağı için atama bulunamadı: ""%1""'"),
			DestinationPattern.Partner);
			
	Else
		
		Message = StrTemplate(NStr("vi = 'Điểm đến không tìm thấy trong CSTT';
									|ru = 'В информационной базе не обнаружено нужное назначение';
									|en = 'Required assignment is not found in the infobase'; fa = 'Required assignment is not found in the infobase';
									|it = 'L''assegnazione richiesta non è stata rilevata nel database informatico';
									|pl = 'W bazie informacyjnej nie wykryto odpowiedniego przeznaczenia';
									|tr = 'Bilgi tabanında gerekli atama bulunamadı'"));
		
	EndIf;
	
	Return Message;
	
EndFunction

Function LinkIsInTemplate(Ref, Template)
	
	For Each Property In Template Do
		
		If Property.Value = Ref Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// List of Attributes used to determine the uniqueness of a directory item
// 
// Returns:
//   String
//
Function KeyAttributes() Export
	
	LinksFields = New Array;
	For Each Attribute In Metadata.Catalogs.Assignments.Attributes Do
		LinksFields.Add(Attribute.Name);
	EndDo;
	
	Return LinksFields;
	
EndFunction

// Creates a new assignment based on key fields or returns an existing one.
//
// Parameters:
//  ParametersOfKey - Structure of KeyAndValue:
//   * Key     - String - name of the prop.
//   * Value - Arbitrary - the value of the props.
//
// Returns:
//   CatalogRef.Assignments
//
Function CreateByKey(ParametersOfKey) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Assignments.Ref AS Ref
	|FROM
	|	Catalog.Assignments AS Assignments
	|WHERE
	|	Assignments.OrderDocument = &OrderDocument
	|	AND Assignments.LineOfBusiness  = &LineOfBusiness
	|	AND Assignments.Partner = &Partner
	|	AND Assignments.Contract = &Contract
	|	AND Assignments.AssignmentType = &AssignmentType
	|	AND Assignments.VATActivityType = &VATActivityType
	|	AND Assignments.RecordsInWarehouseRegisters = &RecordsInWarehouseRegisters
	|	AND Assignments.ControlOnlyStock = &ControlOnlyStock
	|	AND Assignments.ConsiderVATRates = &ConsiderVATRates";
	
	Query.SetParameter("OrderDocument", ParametersOfKey.OrderDocument);
	Query.SetParameter("LineOfBusiness", ParametersOfKey.LineOfBusiness);
	Query.SetParameter("Partner", ParametersOfKey.Partner);
	Query.SetParameter("Contract", ParametersOfKey.Contract);
	Query.SetParameter("AssignmentType", ParametersOfKey.AssignmentType);
	Query.SetParameter("VATActivityType", ParametersOfKey.VATActivityType);
	Query.SetParameter("RecordsInWarehouseRegisters", ParametersOfKey.RecordsInWarehouseRegisters);
	Query.SetParameter("ControlOnlyStock", ParametersOfKey.ControlOnlyStock);
	Query.SetParameter("ConsiderVATRates", ParametersOfKey.ConsiderVATRates);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	If QueryResult.IsEmpty() Then
		
		DestinationPattern = NewSubmenuTemplate();
		FillPropertyValues(DestinationPattern, ParametersOfKey);
		
		DocumentAttributes = Undefined;
		If ValueIsFilled(ParametersOfKey.OrderDocument)Then
			AttributesNames = New Array;
			AttributesNames.Add("Date");
			AttributesNames.Add("Number");
			AttributesNames.Add("DeletionMark");
			AttributesNames.Add(DetailsNameDestinationRecipient(ParametersOfKey.OrderDocument));
			
			DocumentAttributes = Common.ObjectAttributesValues(
				ParametersOfKey.OrderDocument, AttributesNames);
			DeletionMark = DocumentAttributes.DeletionMark;
		Else
			Catalog = Undefined;
			If ValueIsFilled(ParametersOfKey.Contract) Then
				Catalog = ParametersOfKey.Contract;
			ElsIf ValueIsFilled(ParametersOfKey.Partner) Then
				Catalog = ParametersOfKey.Partner;
			ElsIf ValueIsFilled(ParametersOfKey.LineOfBusiness) Then
				Catalog = ParametersOfKey.LineOfBusiness;
			EndIf;
			
			If Catalog <> Undefined Then
				DeletionMark = Common.ObjectAttributeValue(Catalog, "DeletionMark");
			Else
				DeletionMark = False;
			EndIf;
		EndIf;
		
		PurposePresentation = PresentationOfDestinationForRecordingInInformationBase(
			DestinationPattern,
			DocumentAttributes);
			
		Var_Key = Catalogs.Assignments.CreateItem();
		FillPropertyValues(Var_Key, ParametersOfKey);
		Var_Key.Description = PurposePresentation;
		Var_Key.DeletionMark = DeletionMark;
		Var_Key.Write();
	Else
		Var_Key = QueryResult.Select();
		Var_Key.Next();
	EndIf;

	Return Var_Key.Ref;

EndFunction

Function DetailsNameDestinationRecipient(Ref)
	
	TypeMapping = New Map;
	
	TypeMapping.Insert(Type("DocumentRef.ByAssemblyDisassemblyOrder"), "Warehouse");
	TypeMapping.Insert(Type("DocumentRef.TransferOrder"), "DestinationWarehouse");
	TypeMapping.Insert(Type("DocumentRef.InventoryConsumptionOrder"), "Department");
	TypeMapping.Insert(Type("DocumentRef.SalesOrder"), "Partner");
	TypeMapping.Insert(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"), "Partner");
	TypeMapping.Insert(Type("DocumentRef.OrderOfMaterialsForProduction"), "Department");
	TypeMapping.Insert(Type("DocumentRef.SubcontractOrder2_5"), "Partner");
	TypeMapping.Insert(Type("DocumentRef.MaterialProviderOrder2_5"), "Partner");
	TypeMapping.Insert(Type("DocumentRef.RMOrder"), "Department");
	TypeMapping.Insert(Type("DocumentRef.ProductionStage2_2"), "Department");
	TypeMapping.Insert(Type("DocumentRef.ProductionOrder2_2"), "Department");
	Return TypeMapping[(TypeOf(Ref))];
	
EndFunction

#EndRegion

#EndRegion

#Region InfobaseUpdate

Function DataUpdatedForNewApplicationVersion(MetadataAndFilter) Export
	
	// Blocks user changes to the SPR. Activity areas the assignment completion handlers have not yet been completed.
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		If Not Common.IsSubordinateDIBNode() Then
			Return True;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return True;
		EndIf;
	EndIf;
	
	If MetadataAndFilter = Undefined Then
		MetadataAndFilter = InfobaseUpdate.MetadataAndFilterByData(MetadataAndFilter.Data, Undefined);
	EndIf;
	
	If MetadataAndFilter.IsNew Then
		Return True;
	EndIf;
	
	IsDataUpdated = Not InfobaseUpdate.HasDataToProcess(Undefined, MetadataAndFilter.Metadata, MetadataAndFilter.Filter);
	
	DependentDataUpdated = True;
	If IsDataUpdated And MetadataAndFilter.Metadata = Metadata.Catalogs.LinesOfBusiness Then
		DependentDataUpdated = 
				Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.SalesOrder)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.InventoryConsumptionOrder)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.TransferOrder)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.ByAssemblyDisassemblyOrder)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Catalogs.CounterpartyContracts)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.OrderOfMaterialsForProduction)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.RMOrder)
			Or Not InfobaseUpdate.HasDataToProcess(Undefined, Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	EndIf;
	
	Return IsDataUpdated And DependentDataUpdated;
	
EndFunction

#EndRegion

#EndIf

#EndIf
