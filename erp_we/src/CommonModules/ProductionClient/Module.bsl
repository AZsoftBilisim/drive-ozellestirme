////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Production"
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region LaborCosts

// Opens the form for selecting the performer of labor costs in production. Depending on the parameters of the transferred
// unit, teams and/or individuals can be selected in the form.
//
// Parameters:
//  Organization			 - CatalogRef.Companies - the value for the selection of performers.
//  Department		 - CatalogRef.BusinessStructure - defines the list of performers available for selection.
//  Performer			 - CatalogRef.Teams, CatalogRef.Persons - used to position the string
//							at the previously selected value.
//  Date				 - Date - used to determine the opening mode of the form: by employees or individuals.
//  OnlyEmployees		 - Boolean - limits the choice of teams.
//  CallbackDescription	 - CallbackDescription - contains a description of the procedure that will be called when the form is closed.
//
Procedure OpenArtistSelectionForm(Organization, Department, Performer, Date, OnlyEmployees = False, CallbackDescription) Export
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Organization", Organization);
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("Date", Date);
	FormParameters.Insert("OnlyEmployees", OnlyEmployees);
	
	OpenForm("CommonForm.SelectAssignee", FormParameters,,,,,CallbackDescription);
	
EndProcedure

#EndRegion

#Region ManufacturedProduct

// Opens a form to select the recipient in the production. Depending on the item type of the selected lines
// in the form, you can select a division (enterprise structure) or warehouse
//
// Parameters:
//  Form			     - ClientApplicationForm   - Processed form
//  Object               - FormDataStructure - by object type
//  TSParameters		     - Structure          - contains the names (Presentation) of the TS: 
//											    Formname - name of the form table
//                                              The name of the object is the name of the tabular part of the object
//                                              Presentation - Presentation of the tabular part for the output texts
//  ItemsTypes     - Array             - an array of the enumeration values of Typingmaster for which the form opens,
//                                              if undefined, then restrictions on the types is not installed
//  CallbackDescription	 - CallbackDescription - contains a description of the procedure that will be called when the form is closed
//
Procedure OpenRecipientSelectionForm(Form, Object, TSParameters, ItemsTypes = Undefined, CallbackDescription) Export
	
	NameTSForm       = TSParameters.NameTSForm;
	NameTsObject      = TSParameters.NameTsObject;
	PresentationOfTS  = TSParameters.PresentationOfTS;
	
	Items         = Form.Items;
	SelectedRows = Items[NameTSForm].SelectedRows;
	
	If Object[NameTsObject].Count() = 0 Then
		
		ErrorText = NStr("vi = 'Không có hàng nào được nhập vào danh sách ""%1"".';
						|ru = 'В список ""%1"" не введено ни одной строки.';
						|en = 'No lines entered in the ""%1"" list.'; fa = 'No lines entered in the ""%1"" list.';
						|it = 'Nell''elenco ""%1"" non è stata immessa nemmeno una riga.';
						|pl = 'Do listy ""%1"" nie zostały wprowadzone żadne wiersze.';
						|tr = '""%1"" listesinde herhangi bir satır girilmedi.'");
		ErrorText = StrTemplate(ErrorText, PresentationOfTS);
		
		ShowMessageBox(, ErrorText, 45);
		Return;
		
	Else
		
		ProductTypeWork   = PredefinedValue("Enum.ItemsTypes.Work_5");
		
		PresenceOfProhibitedType = False;
		ChoosingUnit      = False;
		SelectWarehouse             = False;
		
		For Each String In SelectedRows Do
			
			RowData = Object[NameTsObject].FindByID(String);
			
			If ItemsTypes <> Undefined 
				And ItemsTypes.Find(RowData.ItemsType) = Undefined Then
				PresenceOfProhibitedType = True;
				Break;
			EndIf;
			
			If RowData.Property("ToExpenseAs")
					And RowData.ToExpenseAs
				Or RowData.ItemsType = ProductTypeWork Then
				ChoosingUnit = True;
			Else
				SelectWarehouse        = True;
			EndIf;
			
			If ChoosingUnit And SelectWarehouse Then
				Break;
			EndIf;
			
		EndDo;
		
		If PresenceOfProhibitedType Then
			
			ErrorText = NStr("vi = 'Đối với mục đã chọn (nhập ""%1""), thao tác không thể được thực hiện.';
							|ru = 'Для выбранной номенклатуры (тип ""%1"") операция не может быть выполнена.';
							|en = 'Operation cannot be executed for the selected items (type ""%1"").'; fa = 'Operation cannot be executed for the selected items (type ""%1"").';
							|it = 'Per l''articolo selezionato (tipo ""%1"") l''operazione non può essere eseguita.';
							|pl = 'Dla wybranej pozycji nomenklatury (typ ""%1"") nie można wykonać operacji.';
							|tr = 'Seçili öğe (tür ""%1"") için işlem gerçekleştirilemez.'");
			ErrorText = StrTemplate(ErrorText, String(RowData.ItemsType));
			
			ShowMessageBox(, ErrorText, 45);
			Return;
			
		EndIf;
		
		If ChoosingUnit And SelectWarehouse Then
			
			ErrorText = NStr("vi = 'Đã chọn các dòng kiểu mặt hàng khác nhau. Không thể thực hiện giao dịch.';
							|ru = 'Выбраны строки с разными типами номенклатуры. Операция не может быть выполнена.';
							|en = 'Rows with different item types are selected. Cannot perform the operation.'; fa = 'Rows with different item types are selected. Cannot perform the operation.';
							|it = 'Sono state selezionate righe con tipi diversi di nomenclatura. L''operazione non può essere eseguita.';
							|pl = 'Wybrano wiersze z różnymi typami wierszy pozycji. Operacja nie może być wykonana.';
							|tr = 'Farklı öğe türlerine sahip satırlar seçildi. İşlem gerçekleştirilemez.'");
			
			ShowMessageBox(, ErrorText, 45);
			Return;
			
		EndIf;
		
		If SelectWarehouse
			And TSParameters.Property("WarehouseInHeader")
			And TSParameters.WarehouseInHeader Then
			
			ErrorText = NStr("vi = 'Kho bãi đối với hàng hóa của danh sách ""%1"" đã chỉ ra trong phần đầu chứng từ.';
							|ru = 'Склад для товаров списка ""%1"" указывается в шапке документа.';
							|en = 'Warehouse for the ""%1"" list goods is specified in the document header.'; fa = 'Warehouse for the ""%1"" list goods is specified in the document header.';
							|it = 'Il magazzino per gli articoli dell''elenco ""%1"" è indicato nell''intestazione del documento.';
							|pl = 'Magazyn dla towarów listy ""%1"" jest podawana w nagłówku dokumentu.';
							|tr = '""%1"" listesindeki ürünlerin ambarı, belgenin üst bilgisinde belirtildi.'");
			ErrorText = StrTemplate(ErrorText, PresentationOfTS);
			
			ShowMessageBox(, ErrorText, 45);
			Return;
			
		EndIf;
		
		If SelectWarehouse
			And TSParameters.Property("LeaveProductsAtSubcontractor")
			And TSParameters.LeaveProductsAtSubcontractor Then
			
			ErrorText = NStr("vi = 'Sản phẩm còn lại để xử lý thêm. Không cần chi ra kho bãi.';
							|ru = 'Изделия остаются для последующей обработки. Склад указывать не требуется.';
							|en = 'Products remain for further processing. The warehouse does not need to be specified.'; fa = 'Products remain for further processing. The warehouse does not need to be specified.';
							|it = 'La produzione resta per la successiva elaborazione. Non è richiesto di indicare il magazzino.';
							|pl = 'Wyroby pozostają dla następującego przetwarzania. Wskazanie magazynu nie jest wymagane.';
							|tr = 'Nihai ürünler daha sonraki işlemeler için kalır. Ambarı belirtmeniz gerekmemektedir.'");
			ErrorText = StrTemplate(ErrorText, PresentationOfTS);
			
			ShowMessageBox(, ErrorText, 45);
			Return;
			
		EndIf;
		
		If SelectWarehouse Then
			
			FormParameters = New Structure;
			FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
			
			If TSParameters.Property("Filter") Then
				FormParameters.Insert("Filter", TSParameters.Filter);
			EndIf;
			
			If TSParameters.Property("GroupOfWarehouses") Then
				FormParameters.Insert("GroupOfWarehouses", TSParameters.GroupOfWarehouses);
			EndIf;
			
			OpenForm(
				"Catalog.Warehouses.ChoiceForm",
				FormParameters, Form,,,,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
		If ChoosingUnit Then
			
			OpenForm("Catalog.BusinessStructure.ChoiceForm",, Form,,,,
						  CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure	

#EndRegion

#Region CalculationOfCostShares

// The function checks whether the percentage of cost allocation for output items needs to be updated.
//
// Parameters:
//  TabularSection				 - FormTable	 - form table showing PM;
//  CostAllocationParameters - Structure	 - structure of calculation parameters, See ProductionClientServer.CostAllocationParametersForOutputProducts
//  CachedValues		 - Structure	 - structure of the current line's details cache.
//  AddingRemoving			 - Boolean		 - indicates that the check is called when a PM line is added or deleted.
// 
// Returns:
//  Boolean - true, if it is necessary to update the service details.
//
Function ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(TabularSection, CostAllocationParameters, CachedValues = Undefined, AddingRemoving = False) Export
	
	RowData = TabularSection.CurrentData;
	
	If AddingRemoving Then
		Return True;
	EndIf;
	
	If IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		MethodOfAllocatingFinishedProductCosts = CostAllocationParameters.MethodOfAllocatingFinishedProductCosts;
	Else
		MethodOfAllocatingFinishedProductCosts = RowData[CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts];
	EndIf;
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts) Then
		Return False;
	EndIf;
	
	FieldsToCheck = New Array;
	FieldsToCheck.Add("CostShare");
	FieldsToCheck.Add(CostAllocationParameters.LinkFields);
	
	If ValueIsFilled(CostAllocationParameters.CostGroupingField) Then
		FieldsToCheck.Add(CostAllocationParameters.CostGroupingField);
	EndIf;
	
	If (MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares")
		Or MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByWeight")
		Or MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByVolume")
		Or MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost"))
		And RowData <> Undefined
		And RowData.CostShare = 0 Then
		FieldsToCheck.Add("Count");
	EndIf;
	
	If CostAllocationParameters.ThereIsFieldCanceled Then
		FieldsToCheck.Add("Canceled");
	EndIf;
	
	If RowData <> Undefined
		And CachedValues <> Undefined
		And TMCommonUseClientServer.StructuresAreEqual(
			CachedValues,
			RowData,
			StrConcat(FieldsToCheck,",")) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// It is used to check whether fields are filled in before executing the command to enter a share of the cost.
//
// Parameters:
//  RowData				 - FormDataStructure	 - data of the line where the cost share is entered.
//  CostAllocationParameters - Structure			 - structure of calculation parameters, See ProductionClientServer.CostAllocationParametersForOutputProducts
//  ObjectName					 - String				 - name of the main form detail associated with the object being edited.
// 
// Returns:
//  Boolean - true if the fill check is successful, false otherwise.
//
Function CheckFillingBeforeEnteringCostFraction(RowData, CostAllocationParameters, ObjectName = "Object") Export
	
	If RowData = Undefined Then
		Return False;
	EndIf;
	
	Errors = New Array();
	
	If Not ValueIsFilled(RowData.Products) Then
		Text = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Mặt hàng';
																			|ru = 'Номенклатура';
																			|en = 'Items'; fa = 'اقلام';
																			|it = 'Articolo';
																			|pl = 'Pozycja';
																			|tr = 'Öğe'"));
		Error = New Structure("Field, Text", "Products", Text);
		Errors.Add(Error);
	EndIf;
	
	If (CommonClientServer.HasAttributeOrObjectProperty(RowData, "NumberOfPackages")
			And RowData.NumberOfPackages = 0
			Or RowData.Count = 0)
		And (Not CostAllocationParameters.ThereIsParameterizationOfResourceSpecification
			Or CostAllocationParameters.ThereIsParameterizationOfResourceSpecification And Not RowData.CalculationByFormula) Then
		
		Text = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Số lượng';
																			|ru = 'Количество';
																			|en = 'Quantity'; fa = 'مقدار';
																			|it = 'Quantità';
																			|pl = 'Ilość';
																			|tr = 'Miktar'"));
		
		If CommonClientServer.HasAttributeOrObjectProperty(RowData, "NumberOfPackages") Then
			Error = New Structure("Field, Text", "NumberOfPackages", Text);
		Else
			Error = New Structure("Field, Text", "Count", Text);
		EndIf;
		
		Errors.Add(Error);
		
	EndIf;
	
	If Not AvailableDecryptionOfCalculationOfShareOfCost(RowData, CostAllocationParameters) Then
		Text = NStr("vi = 'Không đủ quyền truy cập để mở biểu mẫu giải mã để tính toán chia sẻ chi phí.';
					|ru = 'Недостаточно прав доступа для открытия формы расшифровки расчета доли стоимости.';
					|en = 'Insufficient access rights to open the cost share calculation drill-down form.'; fa = 'Insufficient access rights to open the cost share calculation drill-down form.';
					|it = 'Permessi di accesso insufficienti per l''apertura del form di decodifica del conteggio della parte di costo.';
					|pl = 'Za mało praw dostępu, aby otworzyć formularz rozszyfrowania w celu obliczenia udziału wartości.';
					|tr = 'Maliyet payı hesaplamanın detaylandırma formunun açılması için yetersiz erişim yetkisi.'");
		Error = New Structure("Field, Text", "CostShare", Text);
		Errors.Add(Error);
	EndIf;
	
	UserErrors = Undefined;

	For Each Error In Errors Do
		Field = StrTemplate(ObjectName + ".%1[%2].%3", CostAllocationParameters.TSName, Format(RowData.LineNumber - 1, "NZ=0; NG=0"), Error.Field);
		CommonClientServer.AddUserError(UserErrors, Field, Error.Text, "");
	EndDo;

	ClearMessages();
	CommonClientServer.ReportErrorsToUser(UserErrors);

	Return Errors.Count() = 0;

EndFunction

#EndRegion

#Region BackflushProduction_

// Arrange production without an order based on.
// 
// Parameters:
//  ReferencesArrray - Array of DocumentRef
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure ToArrangeProductionWithoutOrderOnBasisOf(ReferencesArrray, ExecutionParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("CommonModule.ProductionClient.ToArrangeProductionWithoutOrderOnBasisOf");
	
	CommandExecuteParameters = New Structure("Source");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	DocumentParameters_ = ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders();
	DocumentParameters_.RegistrationPeriod = Date(3999,12,31);
	DocumentParameters_.AutoFill = True;
	
	DocumentParameters_.ListOfData.Add("RecyclableWaste");
	DocumentParameters_.ListOfData.Add("MaterialsAndServices");
	DocumentParameters_.ListOfData.Add("LaborCosts");
	
	DocumentForm = GetForm("Document.BackflushProduction.ObjectForm",, CommandExecuteParameters.Source);
	DocumentParameters_.FormObjects.Insert("BackflushProduction", DocumentForm.Object);
	
	Result = ProductionServerCall.ToArrangeProductionWithoutOrderOnBasisOf(ReferencesArrray, DocumentParameters_);
	ProcessGeneratedDocuments(CommandExecuteParameters.Source, Result, False);
	
EndProcedure

// Process the generated production documents without an order.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Result - Structure
//  NotifyOnClose - Boolean - notify about closure
//  OnCloseNotifyDescription - CallbackDescription - closing notification
//
Procedure ProcessGeneratedDocuments(Form, Result, NotifyOnClose = True, OnCloseNotifyDescription = Undefined) Export
	
	CallbackDescription = Undefined;
	If NotifyOnClose
		And OnCloseNotifyDescription = Undefined Then
		CallbackDescription = New CallbackDescription("UpdateListData_", Form);
	ElsIf NotifyOnClose Then
		CallbackDescription = OnCloseNotifyDescription;
	EndIf;
	
	If Not Result.FormObject = Undefined Then
		
		DocumentForm = GetForm("Document." + Result.DocumentType + ".ObjectForm", Result, Form);
		CopyFormData(Result.FormObject, DocumentForm.Object);
		DocumentForm.UpdateOnOpening = True;
		DocumentForm.Modified = True;
		DocumentForm.CallbackDescriptionOnClose = CallbackDescription;
		DocumentForm.Open();
		
	ElsIf Result.DocumentsList.Count() > 1 Then
		
		OpenForm(
			"DataProcessor.RegisterBackflushProduction.Form.NewDocumentListForm",
			Result,
			Form,,,,
			CallbackDescription);
			
	Else
		
		If Result.ErrorsArray.Count() = 1 Then
			ShowMessageBox(,Result.ErrorsArray[0].Text);
		Else
			For Each CurrentError In Result.ErrorsArray Do
				CurrentError.Message();
			EndDo;
			ShowMessageBox(,NStr("vi = 'Chưa lập chứng từ nào.';
								|ru = 'Не сформировано ни одного документа.';
								|en = 'No document is generated.'; fa = 'No document is generated.';
								|it = 'Non è stato generato un singolo documento.';
								|pl = 'Nie utworzono ani jednego dokumentu.';
								|tr = 'Herhangi bir belge oluşturulmadı.'"));
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region CalculationOfCostShares

Function AvailableDecryptionOfCalculationOfShareOfCost(RowData, CostAllocationParameters) Export
	
	If IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		MethodOfAllocatingFinishedProductCosts = CostAllocationParameters.MethodOfAllocatingFinishedProductCosts;
	Else
		MethodOfAllocatingFinishedProductCosts = RowData[CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts];
	EndIf;
	
	If MethodOfAllocatingFinishedProductCosts = PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost") Then
		ThereIsAccess = ProductionServerCall.AvailableDecryptionOfCalculationOfShareOfCost(MethodOfAllocatingFinishedProductCosts);
	Else
		ThereIsAccess = True;
	EndIf;
	
	Return ThereIsAccess;
	
EndFunction

#EndRegion

#Region MovementOfProductsAndMaterials

// Input command handler based on " Productionserver.Add a command to create a product release on the basis of".
//
// Parameters:
//  ReferencesArrray - Array - Array of links
//  ExecutionParameters - Structure:
//                         * CommandDetails - Structure:
//                            ** Id           - String  - command ID.
//                            ** Presentation           - String  - representation of the team in the form.
//                            ** AdditionalParameters - Structure - Additional command parameters.
//                            ** MultipleChoice      - Boolean - multiple choice flag.
//                        * Form           - ClientApplicationForm - the form from which the command is called.
//                        * IsObjectForm - Boolean - True if the command is called from an object form.
//                        * Source        - FormTable, FormDataStructure - An object or list of the form with the "Link" field.
//
// Returns:
//  Undefined - 
//
Function CreateTransferOfProductsFromPantryBasedOn(ReferencesArrray, ExecutionParameters) Export

	Array = New Array;
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		Array.Add(ReferencesArrray);
	Else
		Array = ReferencesArrray;
	EndIf;
	
	ExecutionParameters.CommandDetails.Insert("ObjectsOfBases", Array);
	CreateProductAndMaterialMovementBasedOn(
		ExecutionParameters.CommandDetails, 
		PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromStoreroom"));
	
EndFunction

// Input command handler based on " Productionserver.Add a command to create a transfer of material based on".
//
// Parameters:
//  ReferencesArrray - Array - Array of links
//  ExecutionParameters - Structure:
//                         * CommandDetails - Structure:
//                            ** Id           - String  - command ID.
//                            ** Presentation           - String  - representation of the team in the form.
//                            ** AdditionalParameters - Structure - Additional command parameters.
//                            ** MultipleChoice      - Boolean - multiple choice flag.
//                        * Form           - ClientApplicationForm - the form from which the command is called.
//                        * IsObjectForm - Boolean - True if the command is called from an object form.
//                        * Source        - FormTable, FormDataStructure - An object or list of the form with the "Link" field.
//
// Returns:
//  Undefined - 
//
Function CreateTransferOfMaterialsToPantryBasedOn(ReferencesArrray, ExecutionParameters) Export
	
	Array = New Array;
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		Array.Add(ReferencesArrray);
	Else
		Array = ReferencesArrray;
	EndIf;
	
	ExecutionParameters.CommandDetails.Insert("ObjectsOfBases", Array);
	CreateProductAndMaterialMovementBasedOn(
		ExecutionParameters.CommandDetails, 
		PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom"));
	
EndFunction

Procedure CreateProductAndMaterialMovementBasedOn(CommandDetails, BusinessOperation)
	
	OpeningParameters = ProductionServerCall.ParametersForCreatingProductAndMaterialMovementBasedOn(
		CommandDetails.ObjectsOfBases, BusinessOperation);
	
	If OpeningParameters.CheckResults.HasErrors Then
		
		InvoicesClient.ReportErrorsInFillingInInternalInvoice(OpeningParameters.CheckResults.ErrorText);
		
	Else
		
		CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
		FillPropertyValues(CommandExecuteParameters, CommandDetails.AdditionalParameters);
		
		OpenForm(
			"Document.MovementOfProductsAndMaterials.ObjectForm",
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
		
	EndIf;
	
EndProcedure

// Input command handler based on " Productionserver.Add a command to create an issue of productionwithout an order based on".
//
// Parameters:
//  ReferencesArrray - Array - Array of links
//  ExecutionParameters - Structure:
//                         * CommandDetails - Structure:
//                            ** Id           - String  - command ID.
//                            ** Presentation           - String  - representation of the team in the form.
//                            ** AdditionalParameters - Structure - Additional command parameters.
//                            ** MultipleChoice      - Boolean - multiple choice flag.
//                        * Form           - ClientApplicationForm - the form from which the command is called.
//                        * IsObjectForm - Boolean - True if the command is called from an object form.
//                        * Source        - FormTable, FormDataStructure - An object or list of the form with the "Link" field.
//
// Returns:
//  Undefined - 
//
Function CreateProductReleaseWithoutOrderBasedOn(ReferencesArrray, ExecutionParameters) Export

	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("CommonModule.ProductionClient.CreateProductReleaseWithoutOrderBasedOn");
	// End StandardSubsystems.PerformanceMeasurement
	
	Array = New Array;
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		Array.Add(ReferencesArrray);
	Else
		Array = ReferencesArrray;
	EndIf;
	
	ExecutionParameters.CommandDetails.Insert("ObjectsOfBases", Array);
	DocumentParameters_ = New Structure;
	DocumentParameters_.Insert("ObjectsOfBases", Array);
	
	DocumentForm = GetForm("Document.MovementOfProductsAndMaterials.ObjectForm",,, ExecutionParameters.Form,);
	DocumentParameters_.Insert("FormObject", DocumentForm.Object);
	
	FormIdentifier = String(ExecutionParameters.Form.UUID);
	DocumentParameters_.Insert("FormIdentifier", FormIdentifier);
	
	Result = ProductionServerCall.DocumentsMovementOfProductsAndMaterialsByParameters(DocumentParameters_);
	
	If Result.Property("OpenNewForm_") Then
		
		CopyFormData(DocumentParameters_.FormObject, DocumentForm.Object);
		DocumentForm.UpdateOnOpening = True;
		DocumentForm.Modified = True;
		DocumentForm.Open();
		
	ElsIf Result.NumberOfDocumentsCreated > 1 Then
		
		InvoicesClient.OpenFormForCreatedDocuments(Result, ExecutionParameters.Form);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Không một chứng từ nào được tạo ra. Không có sản phẩm yêu cầu chuyển đến kho.';
							|ru = 'Не сформировано ни одного документа. Отсутствует продукция, требующая передачи на склад.';
							|en = 'No document was generated. Products that require transfer to the warehouse are missing.'; fa = 'No document was generated. Products that require transfer to the warehouse are missing.';
							|it = 'Non è stato creato nessun documento. Manca la produzione che necessita un passaggio al magazzino.';
							|pl = 'Nie utworzono żadnego dokumentu. Brak wierszy pozycji wymagających przesłania do magazynu.';
							|tr = 'Herhangi bir belge oluşturulmadı. Ambara transfer edilmesini gereken herhangi bir imal edilen ürün bulunmamaktadır.'"));
		
	EndIf;
	
EndFunction

#EndRegion

#Region FillType

// Fills in the service details in the line based on the selected warehouse
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  Parameters			 - Structure - auxiliary parameters to fill in.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInShopPantryAttribute(CurrentRow, Parameters, CachedValues) Export
	
	WarehouseFieldName = "Warehouse";
	WarehouseValue_ = Undefined;
	FillInTheDepartment = False;
	
	If Parameters <> Undefined Then
		
		If Parameters.Property("WarehouseFieldName") Then
			WarehouseFieldName = Parameters.WarehouseFieldName;	
		EndIf;
			
		If Parameters.Property("FillInTheDepartment") Then
			FillInTheDepartment = Parameters.FillInTheDepartment;	
		EndIf;		
		
		Parameters.Property("WarehouseValue_", WarehouseValue_);
		
	EndIf;
	
	If WarehouseValue_ = Undefined Then
		WarehouseValue_ = CurrentRow[WarehouseFieldName];
	EndIf;
	
	If ValueIsFilled(WarehouseValue_) And TypeOf(WarehouseValue_) = Type("CatalogRef.Warehouses") Then
		
		WarehouseProperties = CachedValues.WarehouseProperties_.Get(WarehouseValue_);
		
		If WarehouseProperties = Undefined Then
			
			ExceptionText = 
				NStr("vi = 'Một nỗ lực để điền vào các chi tiết dịch vụ dựa trên kho được chọn trên máy khách.';
					|ru = 'Попытка заполнения служебных реквизитов на основании выбранного склада на клиенте.';
					|en = 'Attempt to fill in service attributes based on the selected warehouse on client.'; fa = 'Attempt to fill in service attributes based on the selected warehouse on client.';
					|it = 'Tentativo di compilazione dei requisiti di servizio in base al magazzino selezionato per il cliente.';
					|pl = 'Próba wypełnienia służbowych atrybutów na podstawie wybranego magazynu dla klienta.';
					|tr = 'Müşterideki seçilen ambar temelinde servis özniteliklerini doldurma denemesi.'");
			Raise ExceptionText;
			
		EndIf;	
		
		ShopFloorStockroom = WarehouseProperties.ShopFloorStockroom;
		Department = WarehouseProperties.Department;
		
	Else
		
		ShopFloorStockroom = False;
		Department = Undefined;
		
	EndIf;
	
	CurrentRow.ShopFloorStockroom = ShopFloorStockroom;
	
	If FillInTheDepartment And CurrentRow.ShopFloorStockroom Then
		CurrentRow.Department = Department;
	EndIf;
	
	If CurrentRow.Property("MustBeRoundOff") Then
		CurrentRow.MustBeRoundOff = Not CurrentRow.ShopFloorStockroom;	
	EndIf;	
	
EndProcedure

#EndRegion

#Region Other

// Types of costs for choosing a calculation article.
// 
// Parameters:
//  TSName - String
// 
// Returns:
//  Array of EnumRef.CostTypes
Function TypesOfCostsForChoosingCalculationArticle(TSName) Export
	
	CostTypes = New Array;
	
	If TSName = "MaterialsAndServices"
		Or TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "MaterialsAndWorksConsumption" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Material_"));
	ElsIf TSName ="LaborCosts" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Payroll"));
	ElsIf TSName = "RecyclableWaste"
		Or TSName = "SideAndIntermediateRelease" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Material_"));
		CostTypes.Add(PredefinedValue("Enum.CostTypes.RecyclableWaste"));
	EndIf; 
	
	Return CostTypes;
	
EndFunction

// Handler for an input command based on " Document.Actioninvocation.Creating an act of complete internal work".
//
// Parameters:
//  ReferencesArrray - Array - Array of links
//  ExecutionParameters - Structure:
//                         * CommandDetails - Structure:
//                            ** Id           - String  - command ID.
//                            ** Presentation           - String  - representation of the team in the form.
//                            ** AdditionalParameters - Structure - Additional command parameters.
//                            ** MultipleChoice      - Boolean - multiple choice flag.
//                        * Form           - ClientApplicationForm - the form from which the command is called.
//                        * IsObjectForm - Boolean - True if the command is called from an object form.
//                        * Source        - FormTable, FormDataStructure - An object or list of the form with the "Link" field.
//
// Returns:
//  Undefined - 
//
Function CreateActOfCompletedInternalWorksOnBasisOf(ReferencesArrray, ExecutionParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("CommonModule.ProductionClient.CreateActOfCompletedInternalWorksOnBasisOf");
	// End StandardSubsystems.PerformanceMeasurement
	
	ClearMessages();
	
	CheckResult = ProductionServerCall.CreateActOfCompletedInternalWorksVerificationOfGrounds(ReferencesArrray);
	If CheckResult.Property("HasErrors") Then
		CommonClient.MessageToUser(CheckResult.ErrorText);
	Else
		BaseParameters = New Structure;
		BaseParameters.Insert("ObjectsOfBases",	ReferencesArrray);
		BaseParameters.Insert("HeaderAttributes",	CheckResult.HeaderAttributes);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("Basis", BaseParameters);
		
		CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
		FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
		
		FormName = "Document.InternalAcceptanceCertificate.ObjectForm";
		OpenForm(
				FormName,
				OpeningParameters,
				CommandExecuteParameters.Source,
				CommandExecuteParameters.Uniqueness,
				CommandExecuteParameters.Window,
				CommandExecuteParameters.URL);
	EndIf;
	
EndFunction

#EndRegion

#EndRegion
