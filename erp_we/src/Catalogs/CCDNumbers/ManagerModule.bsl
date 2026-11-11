#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the parameters of the customs declaration - the registration number and a sign of whether the goods were declared in the Russian Federation.
// Procedure for obtaining the registration number of the customs declaration See VATAccountingClientServerLocalization.CheckCorrectnessOfCustomsDeclarationNumber.
// If the Type number parameter is passed, which contains a non-empty value, then the registration number will be filled
// in depending on the parameter value.
// If the registration number takes the value of an empty string, a sign will be set that the goods were not declared in the Russian Federation.
//
// Parameters:
//	CustomsDeclarationNumber - String - customs Declaration number or registration number of the customs Declaration.
//	CCDNumberType - EnumRef.CCDNumberTypes, Undefined - the type OF THE Catalog ITEM OF THE License Plate number.
//
// Returns:
//	Structure - a collection containing the following properties:
//		* RegistrationNumber	- String -the registration number of the customs declaration or an empty line 
//											if it could not be determined.
//		* GoodsSequenceNumber - String - The serial number of the product from column 32 DT.
//		* ErrorCode				- Number - error code.
//		* ImportingCountryIsNotRF		- Boolean - a sign that the goods were not declared in the Russian Federation.
//
Function RegistrationNumberAndCountryOfImportation(CustomsDeclarationNumber, CCDNumberType = Undefined) Export
	
	TheseNumbers = New Structure;
	TheseNumbers.Insert("RegistrationNumber", "");
	TheseNumbers.Insert("GoodsSequenceNumber", "");
	TheseNumbers.Insert("ErrorCode", 0);
	TheseNumbers.Insert("ImportingCountryIsNotRF", False);
	
	AccountingForTraceableGoodsClientServerLocalization.FillInRegistrationNumberAndCountryOfImportation(
		TheseNumbers,
		CustomsDeclarationNumber,
		CCDNumberType);
	
	Return TheseNumbers;
	
EndFunction

// Returns the date when the goods Declaration was accepted.
// If the customs Declaration number is specified incorrectly or the Declaration was issued 
// by a non-Russian customs authority, an empty date will be returned.
//
// Parameters:
//    CustomsDeclarationNumber - String - customs Declaration number or registration number of the customs Declaration.
//
// Returns:
//    Date - The date of acceptance of the goods declaration, encrypted in the second digit
//                                            of the customs declaration number.
Function DateOfAcceptanceOfGoodsDeclaration(CustomsDeclarationNumber) Export
	
	DateOfAcceptanceOfGoodsDeclaration = '00010101';
	
	If Not ValueIsFilled(CustomsDeclarationNumber) Then
		Return DateOfAcceptanceOfGoodsDeclaration;
	EndIf;
	
	NumberStructure = VATAccountingClientServerLocalization.CheckCorrectnessOfCustomsDeclarationNumber(CustomsDeclarationNumber);
	
	If Not ValueIsFilled(NumberStructure.RegistrationNumber) Then
		Return DateOfAcceptanceOfGoodsDeclaration;
	EndIf;
	
	TDArray = StrSplit(NumberStructure.RegistrationNumber, "/");
	CategoryDateOfAcceptanceOfGoodsDeclaration = TDArray[1];
	
	Return StringFunctionsClientServer.StringToDate(CategoryDateOfAcceptanceOfGoodsDeclaration)
	
EndFunction

// Initializes the structure of parameters for transmitting data to the handler for filling in the directory element of the GTD Number.
//
// Parameters:
//	CustomsDeclarationNumber - String - customs Declaration number or registration number of the customs Declaration.
//	OriginCountry - Undefined, CatalogRef.WorldCountries - Optional, the country of origin of the goods
//																		according to the customs declaration.
//
// Returns:
//	Structure - parameters for filling in an element of the Catalog of the GTD number, including the following properties:
//		* Code - String - Full number of the cargo customs declaration.
//		* OriginCountry - CatalogRef.WorldCountries, Undefined - The country of origin of the goods according to the customs
//																			declaration.
//		* RegistrationNumber - String - The number of the customs declaration.
//		* Products - CatalogRef.Products - required to account for traceable items.
//		* ProductName - String - required to account for traceable items.
//		* AmountByProductBatchID - Number - required to account for traceable items.
//		* GoodsSequenceNumber - String - The serial number of the goods (the value of field No. 32 of the customs declaration).
//		* CCDNumberType - EnumRef.CCDNumberTypes - the CCD room type. The default value is "Numbered".
//		* FillInSerialNumberOfProductAutomatically - Boolean - Indicates that the order number of the item will be calculated
//																	directly from the Code property.
//		* ImportingCountryIsNotRF - Boolean - a sign that the goods were not declared in the Russian Federation.
//
Function ParametersForFillingElement(CustomsDeclarationNumber, OriginCountry = Undefined) Export
	
	FillParameters = New Structure;
	FillParameters.Insert("Code",						CustomsDeclarationNumber);
	FillParameters.Insert("OriginCountry",		?(ValueIsFilled(OriginCountry),
																OriginCountry,
																Catalogs.WorldCountries.EmptyRef()));
	FillParameters.Insert("RegistrationNumber",	"");
	FillParameters.Insert("Products",			"");
	FillParameters.Insert("ProductName",		"");
	FillParameters.Insert("AmountByProductBatchID",				0);
	FillParameters.Insert("GoodsSequenceNumber",	"");
	FillParameters.Insert("CCDNumberType",			Enums.CCDNumberTypes.CCDNumber);
	FillParameters.Insert("FillInSerialNumberOfProductAutomatically", False);
	FillParameters.Insert("ImportingCountryIsNotRF",			False);
	
	Return FillParameters;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String- names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	AttributesToLock.Add("Code");
	AttributesToLock.Add("CCDNumberType");
	AttributesToLock.Add("OriginCountry");
	AttributesToLock.Add("Products");
	AttributesToLock.Add("ProductName");
	AttributesToLock.Add("UnitOfMeasure");
	AttributesToLock.Add("AmountByProductBatchID");
	AttributesToLock.Add("TraceableComponents");
	
	Return AttributesToLock;
	
EndFunction

#Region InfobaseUpdate

// Adds procedures to the list that handle updating information security data for all supported library versions or configurations.
// Called before the start of updating the information security data to build an update plan.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable.
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.CCDNumbers.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.88";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("ba5b5ad9-5a84-4371-9c56-5391566842e7");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.CCDNumbers.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.Comment = NStr("vi = 'Điền mục tin ""Đơn vị tính"" bằng giá trị mặc định ""c"" theo bảng mã hiệu đơn vị đo lường đối với phần tử của danh mục kiểu số đăng ký lô hàng.';
							|ru = 'Заполняет реквизит ""Единица измерения"" значением по умолчанию ""шт"" по ОКЕИ для элементов справочника типа РНПТ.';
							|en = 'Fills in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.'; fa = 'Fills in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.';
							|it = 'Заполняет реквизит ""Единица измерения"" значением по умолчанию ""шт"" по ОКЕИ для элементов справочника типа РНПТ.';
							|pl = 'Fills in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.';
							|tr = 'RNPT tipindeki katalog öğeleri için ""Ölçü birimi"" özniteliğini RÖBS’e göre varsayılan ""adet"" değeriyle doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.PackagesAndUnitsOfMeasure.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.CCDNumbers.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.CCDNumbers.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers data for processing when switching to a new version.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataForProcessing_.Ref AS Ref
	|FROM
	|	Catalog.CCDNumbers AS DataForProcessing_
	|WHERE
	|	DataForProcessing_.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|	AND DataForProcessing_.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
	
	DataForProcessing_ = Query.Execute().Unload().UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, DataForProcessing_);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	UpdatedData	= InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	FullObjectName	= EmptyRef().Metadata().FullName();
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																							FullObjectName);
		
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Số TKHQ"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Номера ГТД"" по обработчику:';
								|en = 'Cannot process the ""CCD numbers"" catalog by the handler:'; fa = 'Cannot process the ""CCD numbers"" catalog by the handler:';
								|it = 'Cannot process the ""CCD numbers"" catalog by the handler:';
								|pl = 'Cannot process the ""CCD numbers"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""GKB numaraları"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Đơn vị tính"" bằng giá trị mặc định ""c"" theo bảng mã hiệu đơn vị đo lường đối với phần tử của danh mục kiểu số đăng ký lô hàng.';
								|ru = '- заполнение реквизита ""Единица измерения"" значением по умолчанию ""шт"" по ОКЕИ для элементов справочника типа РНПТ.';
								|en = '- Filling in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.'; fa = '- Filling in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.';
								|it = '- Filling in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.';
								|pl = '- Filling in the ""Unit of measure"" attribute with the ""pcs"" default value by OKEI for catalog items of the RNPT type.';
								|tr = 'RNPT tipindeki katalog öğeleri için ""Ölçü birimi"" özniteliğini RÖBS dahilindeki varsayılan değer olan ""adet"" ile doldurur.'"));
	
	ClassifierData	= Catalogs.PackagesAndUnitsOfMeasure.FillInUnitsFromClassifier("796");
	UnitOfMeasure		= ClassifierData["796"];
	
	For Each CatalogData In UpdatedData Do
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", CatalogData.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			CatalogObject = CatalogData.Ref.GetObject();
			
			If CatalogObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(CatalogData.Ref);
			Else
				
				If Not ValueIsFilled(CatalogObject.UnitOfMeasure) Then
					CatalogObject.UnitOfMeasure = UnitOfMeasure;
				EndIf;
				
				ExceptionReason = "Record";
				
				If CatalogObject.Modified() Then
					InfobaseUpdate.WriteObject(CatalogObject);
				Else
					InfobaseUpdate.MarkProcessingCompletion(CatalogData.Ref);
				EndIf;
				
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdateTM.ReportFailedProcessing(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				CatalogData.Ref);
			
			If ExceptionReason = "BadData" Then
				IssueDetails = InfobaseUpdateTM.DataProblem(
									CatalogData.Ref,
									Recommendation,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				ExceptionsWhenUpdating.Add(IssueDetails);
			ElsIf ExceptionReason = "Record" Then
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating,
					ObjectsProcessed,
					Parameters);
				
				Raise StrConcat(ListOfDescriptions, Chars.LF);
			EndIf;
			
		EndTry;
	
	EndDo;
	
	If ObjectsProcessed = 0
		And ObjectsWithIssuesCount <> 0 Then
		
		ListOfDescriptions.Add(NStr("vi = 'Bỏ qua tổng số: %1';
									|ru = 'Всего пропущено: %1';
									|en = 'Skipped: %1'; fa = 'Skipped: %1';
									|it = 'Всего пропущено: %1';
									|pl = 'Skipped: %1';
									|tr = 'Toplam atlanan: %1'"));
		
		MessageText = StrTemplate(StrConcat(ListOfDescriptions, Chars.LF), String(ObjectsWithIssuesCount));
		
		Raise MessageText;
		
	EndIf;
	
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																						FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Code");
	Fields.Add("CCDNumberType");
	Fields.Add("NumberOfComponents_");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Data.CCDNumberType <> PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
		Return;
	Else
		PurchasesServerCall.CCDNumbersProcessingReceiptOfSubmission(Data, Presentation, StandardProcessing);
	EndIf;
	
EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	PurchasesServerCall.CCDNumbersProcessingReceiptOfSelectionData(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

// Returns the serial number of the goods from the full number of the customs declaration, for Russia this is the 4 group of characters
// found by the separator "\".
//
// Parameters:
//	CustomsDeclarationNumber - String - Full number of the customs Declaration.
//
// Returns:
//	String - The serial number of the goods (the value of field No. 32 of the customs declaration).
//
Function SerialNumberOfGoodsFromNumberOfCustomsDeclaration(CustomsDeclarationNumber) Export
	
	GoodsSequenceNumber	= "";
	TheseNumbersAreCCD			= StrSplit(CustomsDeclarationNumber, "/");
	
	If TheseNumbersAreCCD.Count() = 4 Then
		GoodsSequenceNumber = TheseNumbersAreCCD[3];
	EndIf;
	
	Return GoodsSequenceNumber;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
