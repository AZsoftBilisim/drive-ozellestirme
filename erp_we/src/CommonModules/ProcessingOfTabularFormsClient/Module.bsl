#Region Public

// Checks whether the selected line is required for executing the command. Displays a message if it is missing.
//
// Parameters:
//  FormTable - FormTable - a form element that contains the table part.
//
// Returns:
//  Boolean - True - execution of the command is possible; False - otherwise.
//
Function SelectedLineToExecuteCommand(FormTable) Export
	
	If Not ValueIsFilled(FormTable.SelectedRows) Then
		ShowMessageBox(, NStr("vi = 'Để thực hiện lệnh cần chọn dòng phần bảng.';
								|ru = 'Для выполнения команды требуется выбрать строку табличной части.';
								|en = 'To execute the command, select a table row.'; fa = 'To execute the command, select a table row.';
								|it = 'Per eseguire il comando, è necessario selezionare una riga della parte tabulare.';
								|pl = 'W celu wykonania polecenia należy wybrać wiersz części tabelarycznej.';
								|tr = 'Komutu yürütmek için tablo bölümünde bir satır seçilmesi gerekir.'"));
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

#Region CheckingPossibilityOfFilling

// Function-constructor of parameters for checking whether the table part can be filled in.
//
// Returns:
//  Structure:
//     * TabularSection - FormDataCollection - the table part that needs to be checked for blankness
//          . if the table part is filled in, after the user confirms it, it is cleared.
//     * TitleOfTablePart - String - name of the table part to be checked, which will be shown in the verification messages
//     * CheckForPromiscuity - Boolean - indicates the need to check whether the document
//          is not completed. if the document is completed, after the user confirms it, it is canceled.
//     * CheckedAttributes - Structure - object details that need to be filled in,
//          where the Key is the name of the item and the Value is its header.
//
Function FillVerificationParameters() Export
	
	FillVerificationParameters = New Structure;
	FillVerificationParameters.Insert("TabularSection", Undefined);
	FillVerificationParameters.Insert("TitleOfTablePart", "");
	FillVerificationParameters.Insert("CheckForPromiscuity", True);
	FillVerificationParameters.Insert("CheckedAttributes", New Structure);
	
	Return FillVerificationParameters;
	
EndFunction

// Checks whether the table part of the object can be filled in.
//
// Parameters:
//  Form - ClientApplicationForm - object form
//  NotificationAfterVerification - CallbackDescription - description of the procedure that will be called if filling is possible
//      with the following parameters:
//          The result Is Boolean - always True
//          Additional parameters - Arbitrary - parameters specified in the notification after the check when creating.
//  FillVerificationParameters - Structure - (See ProcessingOfTabularFormsClient.FillVerificationParameters).
//
Procedure CheckIfItCanBeFilledIn(Form, NotificationAfterVerification, FillVerificationParameters) Export
	
	ClearMessages();
	
	ErrorTemplate = NStr("vi = 'Chưa điền trường ""%1""';
						|ru = 'Поле ""%1"" не заполнено';
						|en = '""%1"" is required'; fa = '""%1"" is required';
						|it = 'Il campo ""%1"" non è compilato';
						|pl = 'Pole ""%1"" nie jest wypełnione';
						|tr = '""%1"" alanı doldurulmadı'");
	Cancel = False;
	For Each Item In FillVerificationParameters.CheckedAttributes Do
		
		If Not ValueIsFilled(Form.Object[Item.Key]) Then
			ErrorText = StrTemplate(ErrorTemplate, Item.Value);
			CommonClientServer.MessageToUser(ErrorText,, Item.Key, "Object", Cancel);
		EndIf;
		
	EndDo;
	
	If Cancel Then
		Return;
	EndIf;
	
	NeedToSpread = FillVerificationParameters.CheckForPromiscuity And Form.Object.Posted;
	NeedToClearTS = ValueIsFilled(FillVerificationParameters.TabularSection);
	QueryText = "";
	
	If IsBlankString(FillVerificationParameters.TitleOfTablePart) Then
		If NeedToSpread And NeedToClearTS Then
			QueryText = NStr("ru = 'Заполнение возможно только в непроведенном документе.
				|Табличная часть будет очищена. Очистить и отменить проведение?';
				|vi = 'Cannot edit posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?';
				|en = 'Cannot edit posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?'; fa = 'Cannot edit posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?';
				|it = 'Cannot edit posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?';
				|pl = 'Cannot edit posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?';
				|tr = 'Doldurma işlemi yalnızca kaydedilmemiş belgede yapılabilir.
				|Tablo temizlenecektir. Temizleyip kaydetme iptal edilsin mi?'");
		ElsIf NeedToSpread And Not NeedToClearTS Then
			QueryText = NStr("ru = 'Заполнение возможно только в непроведенном документе, отменить проведение?';
							|vi = 'You can fill in only unposted documents. Undo posting?';
							|en = 'You can fill in only unposted documents. Undo posting?'; fa = 'You can fill in only unposted documents. Undo posting?';
							|it = 'You can fill in only unposted documents. Undo posting?';
							|pl = 'You can fill in only unposted documents. Undo posting?';
							|tr = 'Doldurma yalnızca kaydedilmemiş bir belgede mümkündür, kaydetme iptal edilsin mi?'");
		ElsIf Not NeedToSpread And NeedToClearTS Then
			QueryText = NStr("ru = 'Табличная часть будет очищена, продолжить?';
							|vi = 'Tabular section will be cleared. Continue?';
							|en = 'Tabular section will be cleared. Continue?'; fa = 'Tabular section will be cleared. Continue?';
							|it = 'Tabular section will be cleared. Continue?';
							|pl = 'Tabular section will be cleared. Continue?';
							|tr = 'Tablo temizlenecek, devam edilsin mi?'");
		EndIf;
	Else
		If NeedToSpread And NeedToClearTS Then
			QueryText = NStr("vi = 'Chỉ có thể điền ""%1"" trong chứng từ chưa kết chuyển.
				|Phần bảng sẽ bị xóa. Xóa và hủy kết chuyển?';
				|ru = 'Заполнение ""%1"" возможно только в непроведенном документе.
				|Табличная часть будет очищена. Очистить и отменить проведение?';
				|en = 'Cannot edit ""%1"" in posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?'; fa = 'Cannot edit ""%1"" in posted documents.
				|The table will be cleared. The document will be unposted. Do you want to continue?';
				|it = 'La compilazione %1 è possibile solo nel documento non registrato.
				| La parte tabulare verrà cancellata. Cancellare e annullare l''esecuzione?';
				|pl = 'Wypełnienie ""%1"" jest możliwe tylko w niezaksięgowanym dokumencie.
				|Część tabelaryczna będzie oczyszczona. Oczyścić i anulować księgowanie?';
				|tr = '""%1"" doldurulması yalnızca kaydedilmemiş belgede mümkündür.
				|Tablo bölümü temizlenecektir. Kayıt silinsin ve iptal edilsin mi?'");
		ElsIf NeedToSpread And Not NeedToClearTS Then
			QueryText = NStr("vi = 'Việc điền ""%1"" chỉ có thể có trong một chứng từ chưa kết chuyển, hủy kết chuyển?';
							|ru = 'Заполнение ""%1"" возможно только в непроведенном документе, отменить проведение?';
							|en = 'Population of ""%1"" is possible only in an unposted document, cancel posting?'; fa = 'Population of ""%1"" is possible only in an unposted document, cancel posting?';
							|it = 'La compilazione %1 è possibile solo nel documento non registrato, annullare l''esecuzione?';
							|pl = 'Wypełnienie ""%1"" jest możliwe tylko w niezaksięgowanym dokumencie, anulować księgowanie?';
							|tr = '""%1"" doldurulması yalnızca kaydedilmemiş belgede mümkündür, kaydetmeyi iptal et?'");
		ElsIf Not NeedToSpread And NeedToClearTS Then
			QueryText = NStr("vi = 'Phần bảng ""%1""sẽ bị xóa, tiếp tục?';
							|ru = 'Табличная часть ""%1"" будет очищена, продолжить?';
							|en = 'The %1 table will be cleared. Do you want to continue?'; fa = 'The %1 table will be cleared. Do you want to continue?';
							|it = 'La parte tabulare %1 sarà cancellata, continuare?';
							|pl = 'Część tabelaryczna ""%1"" będzie oczyszczona, kontynuować?';
							|tr = 'Tablo bölümü ""%1"" temizlenecek, devam edilsin mi?'");
		EndIf;
		If Not IsBlankString(QueryText) Then
			QueryText = StrTemplate(QueryText, FillVerificationParameters.TitleOfTablePart);
		EndIf;
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("NotificationAfterVerification", NotificationAfterVerification);
	AdditionalParameters.Insert("NeedToSpread",        NeedToSpread);
	AdditionalParameters.Insert("TabularSection",          FillVerificationParameters.TabularSection);
	If Not IsBlankString(QueryText) Then
		CallbackDescription = New CallbackDescription("CheckPossibilityOfFillingInAfterQuestion",
			ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		CheckPossibilityOfFillingInAfterRecording(True, AdditionalParameters);
	EndIf; 
	
EndProcedure

#EndRegion

#Region SplittingString

// Constructor function for additional parameters for splitting a string.
//
// Returns:
//  Structure:
//     * FieldNameQuantity - String - name of the field to split by
//     * Title - String - title of the number entry form
//     * AllowZeroCount - Boolean - indicates that the source and destination strings may contain 0
//     * Count - Undefined, Number - the number that will be displayed in the number editing form;
//          if Undefined, the number taken from the source string will be shown.
//     * MaximumAllowedValue - Number - upper limit of quantity indication.
//
Function StringSplittingParameters() Export
	
	StringSplittingParameters = New Structure;
	StringSplittingParameters.Insert("FieldNameQuantity", "NumberOfPackages");
	StringSplittingParameters.Insert("Title", NStr("vi = 'Hãy nhập số lượng hàng hóa trong dòng mới';
													|ru = 'Введите количество товара в новой строке';
													|en = 'Enter quantity of goods in a new line'; fa = 'Enter quantity of goods in a new line';
													|it = 'Inserire quantità di merce nella nuova riga';
													|pl = 'Wprowadź ilość towaru w nowym wierszu';
													|tr = 'Ürünün miktarını yeni bir satıra gir'"));
	StringSplittingParameters.Insert("AllowZeroCount", True);
	StringSplittingParameters.Insert("Count", Undefined);
	StringSplittingParameters.Insert("MaximumAllowedValue", 0);
	
	Return StringSplittingParameters;
	
EndFunction

// Splits the selected line into two by the number entered.
//
// Parameters:
//  TabularSection - FormDataCollection - table part to split the selected row in
//  FormTable - FormTable - form element containing the table part
//  NotificationAfterSplitting - CallbackDescription - description of the procedure that will be called after the split,
//      with the value of the split result passed: data formelementcollection - a new line obtained by the split;
//      Undefined - no partitioning was performed.
//  StringSplittingParameters - Structure - (See ProcessingOfTabularFormsClient.StringSplittingParameters).
//
Procedure SplitRow(TabularSection, FormTable, NotificationAfterSplitting = Undefined, StringSplittingParameters = Undefined) Export
	
	If StringSplittingParameters = Undefined Then
		StringSplittingParameters = StringSplittingParameters();
	EndIf;
	
	Cancel = False;
	If Not SelectedLineToExecuteCommand(FormTable) Then
		Cancel = True;
	ElsIf FormTable.CurrentData[StringSplittingParameters.FieldNameQuantity] = 0
		And Not StringSplittingParameters.AllowZeroCount Then
		ShowMessageBox(, NStr("vi = 'Không thể chia tách dòng có số lượng bằng 0.';
								|ru = 'Невозможно разбить строку с нулевым количеством.';
								|en = 'Cannot break the line with zero quantity.'; fa = 'Cannot break the line with zero quantity.';
								|it = 'Impossibile dividere la riga con quantità zero.';
								|pl = 'Nie można podzielić wiersz z zerową ilością.';
								|tr = 'Satırı sıfır sayı ile bölmek mümkün değildir.'"));
		Cancel = True;
	ElsIf TMCommonUseClientServer.HasObjectAttribute(TabularSection[0], "ProductsInSet") Then
		SetsClient.BeforeDeletingRowOfTablePart(FormTable, FormTable.Name, Cancel, True);
	EndIf;
	
	If Cancel Then
		If NotificationAfterSplitting <> Undefined Then
			RunCallback(NotificationAfterSplitting, Undefined);
		EndIf;
		Return;
	EndIf;
	
	If FormTable.CurrentData[StringSplittingParameters.FieldNameQuantity] = 0 Then // copying a string
		AddLineBySplitting(TabularSection, FormTable, 0, NotificationAfterSplitting, StringSplittingParameters);
	Else
		ProcessingParameters = New Structure;
		ProcessingParameters.Insert("TabularSection",           TabularSection);
		ProcessingParameters.Insert("FormItem",             FormTable);
		ProcessingParameters.Insert("NotificationAfterSplitting", NotificationAfterSplitting);
		ProcessingParameters.Insert("StringSplittingParameters", StringSplittingParameters);
		
		EnterQuantityToSplit(ProcessingParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region CopyPasteLines

// Displays a notification window about the number of copied rows.
// Notifies other forms of the event when lines are copied to the clipboard.
// 
// Parameters:
//  RowsCount - Number - the number of rows copied from the table part.
//
Procedure NotifyUserAboutCopyingStrings(RowsCount) Export
	
	TitleText = NStr("vi = 'Đã sao chép dòng';
					|ru = 'Строки скопированы';
					|en = 'Lines are copied'; fa = 'Lines are copied';
					|it = 'Righe copiate';
					|pl = 'Wiersze są skopiowane';
					|tr = 'Satırlar kopyalandı'");
	MessageText = StrTemplate(NStr("vi = ' %1 dòng được sao chép vào clipboard';
									|ru = 'В буфер обмена скопировано %1 строк';
									|en = '%1 lines are copied to the clipboard'; fa = '%1 lines are copied to the clipboard';
									|it = 'Negli Appunti vengono copiate %1 righe';
									|pl = 'Do schowka skopiowano %1 wierszy';
									|tr = '%1 satır panoya kopyalandı'"), RowsCount);
	ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
	
	Notify("CopyingLinesToClipboard");
	
EndProcedure

// Displays a notification window about the number of inserted rows.
// 
// Parameters:
//  RowsCount - Number - the number of rows inserted in the table part.
//
Procedure NotifyUserAboutInsertingRows(RowsCount) Export
	
	TitleText = NStr("vi = 'Đã chèn dòng';
					|ru = 'Строки вставлены';
					|en = 'Lines are inserted'; fa = 'Lines are inserted';
					|it = 'Righe inserite';
					|pl = 'Wiersze są wstawione';
					|tr = 'Satırlar eklendi'");
	MessageText = StrTemplate(NStr("vi = 'Từ bộ đệm trao đổi đã chèn %1 dòng';
									|ru = 'Из буфера обмена вставлено %1 строк';
									|en = '%1 lines are inserted from the clipboard'; fa = '%1 lines are inserted from the clipboard';
									|it = 'Negli Appunti vengono inserite le %1righe';
									|pl = 'Ze schowka wklejono %1 wierszy';
									|tr = '%1 satır panodan eklendi'"), RowsCount);
	ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
	
EndProcedure

#EndRegion

#Region ImportGoodsFromExternalFiles

// Function-constructor of parameters for the item loading form from external sources.
//
// Returns:
//  Structure:
//     * Title - String - title of the item upload form
//     * AdditionalExplanationWhenUploading - String - additional explanation displayed on the form when loading the item
//     * FilterParameters - Structure - sets the filter conditions for the loaded item,
//          where the Key is the name of the item details, and the Value is the desired value;
//          You can also use the Segment nomenclature key to select a segment of the nomenclature.
//     * CheckCharacteristicPopulation - Boolean - specifies whether to check whether the characteristics are filled in
//     * SkipItemVerification - Boolean - indicates the need to skip the item filling check;
//     		ignored if the option to load packing lists is enabled.
//     * FillInThePartnerSNomenclature - CatalogRef.Partners - when specifying a supplier, defines the ability
//          for the loaded item to fill in the supplier's item associated with it.
//
//     * ImportQuantity - Boolean - determines whether the number of units can be loaded
//     * ImportPrices - Boolean - determines whether prices can be loaded
//     * ImportAmounts - Boolean - determines whether amounts can be loaded
//     * ImportCCD - Boolean - determines whether GTD numbers can be loaded
//
//     * ImportInventory - Boolean - determines whether the minimum and maximum inventory can be loaded
//     * ImportDiscounts - Boolean - determines whether manual discounts can be loaded
//     * ImportPackingLists - Boolean - determines whether packing lists can be loaded
//
//     * AmountsRecalculate - Boolean - specifies whether to recalculate the amounts of the loaded item
//     * PriceIncludesVAT - Boolean - indicates whether VAT is included in the price and amount of the loaded item
//     * Organization - CatalogRef.Companies - determines the filling of VAT rates
//     * VATTaxation - EnumRef.VATTaxationTypes - determines whether the VAT rate is filled in
//     * FillingDate - Date - specifies the date on which the VAT rate is filled in
//     * ThisIsReusablePackage - Boolean - indicates whether the loaded container is returnable
//
//     * ComponentsPriceParameters - Structure - description of price filling parameters for kit components:
//        ** Date - Date - date of price receipt
//        ** Currency - CatalogRef.Currencies - price currency
//        ** Terms - CatalogRef.TermsOfSale - agreement under which prices must be obtained;
//              not filled in if you need to fill in prices by price type.
//        ** PriceKind - CatalogRef.TypesOfPrices - the kind of price that determines the algorithm for calculating the prices;
//              it is not filled in if you need to fill in the prices under the agreement.
//
Function ProductLoadingParameters() Export
	
	ProductLoadingParameters = New Structure();
	ProductLoadingParameters.Insert("Title", NStr("vi = 'Đang tải sản phẩm từ các tệp bên ngoài';
													|ru = 'Загрузка товаров из внешних файлов';
													|en = 'Import goods from external files'; fa = 'ورود کالاها از فایل‌های خارجی';
													|it = 'Download delle merci dai file esterni';
													|pl = 'Pobieranie towarów z plików zewnętrznych';
													|tr = 'Harici dosyalardan ürün yükleme'"));
	ProductLoadingParameters.Insert("AdditionalExplanationWhenUploading", "");
	
	ProductLoadingParameters.Insert("CheckCharacteristicPopulation", False);
	ProductLoadingParameters.Insert("SkipItemVerification", False);
	ProductLoadingParameters.Insert("FillInThePartnerSNomenclature",  Undefined);
	
	ProductLoadingParameters.Insert("ImportQuantity", True);
	ProductLoadingParameters.Insert("ImportPrices",       False);
	ProductLoadingParameters.Insert("ImportAmounts",      False);
	ProductLoadingParameters.Insert("ImportCCD",        False);
	
	ProductLoadingParameters.Insert("ImportInventory",           False);
	ProductLoadingParameters.Insert("ImportDiscounts",           False);
	ProductLoadingParameters.Insert("ImportPackingLists", False);
	
	ProductLoadingParameters.Insert("AmountsRecalculate", True);
	ProductLoadingParameters.Insert("PriceIncludesVAT",    True);
	ProductLoadingParameters.Insert("Organization",        Undefined);
	ProductLoadingParameters.Insert("VATTaxation",
		PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT"));
	ProductLoadingParameters.Insert("FillingDate",     '00010101');
	ProductLoadingParameters.Insert("ThisIsReusablePackage",  False);
	
	ProductLoadingParameters.Insert("ComponentsPriceParameters",
		New Structure("Date,Currency,Terms,PriceKind"));
	
	ProductLoadingParameters.Insert("FilterParameters", New Structure);
	
	Return ProductLoadingParameters;
	
EndFunction

// Opens the item loading form from an external source.
//
// Parameters:
//  ImportParameters - See ProductLoadingParameters
//  ImportNotification - CallbackDescription - description of the procedure that will be called after loading,
//      passing the value of the loading result: String-address in temporary storage; Undefined - no download was performed.
//
Procedure ShowProductUploadForm(ImportParameters, ImportNotification) Export
	
	OpenForm("DataProcessor.ImportGoodsFromExternalFiles.Form.Form", ImportParameters,
		ImportNotification.Module, , , , ImportNotification);
	
EndProcedure

// Function-constructor of parameters for the item loading form from external sources for plans.
//
// Returns:
//  Structure:
//     * Title - String - title of the item upload form
//     * FilterParameters - Structure - sets the filtering conditions for the uploaded item, where the key is the name of the item's Attribute and the Value is the value you are looking for:
//       ** ItemsType - Array of EnumRef.ItemsTypes - 
//
//     * PlanProfile - CatalogRef.PlanProfiles - setting up plan completion
//     * PlanByAmount - Boolean - flag for planning by prices and amounts
//     * CrossTable - Boolean - flag for creating a plan in the cross-table
//
//     * AddressOfThePeriodTable - String - address in the temporary storage of the period table
//     * GoodsTableAddress - String - address in the temporary storage of the product table
//
//     * Partner - CatalogRef.Partners - partner who participates in business operations with the company according to the plan
//     * Department - CatalogRef.BusinessStructure - the division for which the plan is formed.
//
Function ProductLoadingParametersForPlans() Export
	
	ProductLoadingParameters = New Structure();
	ProductLoadingParameters.Insert("Title", NStr("vi = 'Đang tải sản phẩm từ các tệp bên ngoài';
													|ru = 'Загрузка товаров из внешних файлов';
													|en = 'Import goods from external files'; fa = 'ورود کالاها از فایل‌های خارجی';
													|it = 'Download delle merci dai file esterni';
													|pl = 'Pobieranie towarów z plików zewnętrznych';
													|tr = 'Harici dosyalardan ürün yükleme'"));
	
	ProductLoadingParameters.Insert("PlanProfile",            PredefinedValue("Catalog.PlanProfiles.EmptyRef"));
	ProductLoadingParameters.Insert("PlanByAmount",  False);
	ProductLoadingParameters.Insert("CrossTable",        False);
	
	ProductLoadingParameters.Insert("AddressOfThePeriodTable", "");
	ProductLoadingParameters.Insert("GoodsTableAddress",  "");
	
	ProductLoadingParameters.Insert("Partner",       PredefinedValue("Catalog.Partners.EmptyRef"));
	ProductLoadingParameters.Insert("Department", PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	ProductLoadingParameters.Insert("ProductionProcessType", PredefinedValue("Enum.ProductionProcessTypes.EmptyRef"));
	ProductLoadingParameters.Insert("FilterParameters", New Structure);
	
	Return ProductLoadingParameters;
	
EndFunction

// Opens the item loading form from an external source.
//
// Parameters:
//  ImportParameters - See ProductLoadingParametersForPlans
//  ImportNotification - CallbackDescription - description of the procedure that will be called after loading,
//      passing the value of the loading result: String-address in temporary storage; Undefined - no download was performed.
//
Procedure ShowProductUploadFormForPlans(ImportParameters, ImportNotification) Export
	
	OpenForm("DataProcessor.ImportGoodsFromExternalFiles.Form.FormForPlans", ImportParameters,
		ImportNotification.Module, , , , ImportNotification);
	
EndProcedure

#EndRegion

#Region StringCaching

// Saves the current row of the specified table in the cache on the form.
// Before using it, you need to make a one-time call to work with different Parts.Initializereadwritelock().
//
// Parameters:
//  FormTable - FormTable - a form element that contains the table part.
//  Form - ClientApplicationForm - form of the metadata object.
//
Procedure CacheCurLine(FormTable, Form) Export
	
	CurrentData = FormTable.CurrentData;
	LineCache     = New Structure(Form.CachedLines[FormTable.Name]);
	
	If CurrentData <> Undefined Then
		FillPropertyValues(LineCache, CurrentData);
	Else
		For Each KeyAndValue In LineCache Do
			LineCache[KeyAndValue.Key] = Undefined;
		EndDo;
	EndIf;
	
	Form.CachedLines[FormTable.Name] = New FixedStructure(LineCache);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region CheckingPossibilityOfFilling

// Parameters:
// 	QuestionResult - DialogReturnCode
// 	AdditionalParameters - Structure:
// 		* Form - ManagedFormExtensionForObjects
// 		* NeedToSpread - Boolean
//
Procedure CheckPossibilityOfFillingInAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	If AdditionalParameters.NeedToSpread Then
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.UndoPosting);
		
		// The form uses special procedures to record the document. Rejection of modality.
		If TMCommonUseClientServer.HasObjectAttribute(Form, "NotExecuteCheck1BeforeWrite") Then
			WriteParameters.Insert("ActionAfterRecording",
				New CallbackDescription("CheckPossibilityOfFillingInAfterRecording", ThisObject, AdditionalParameters));
			
			Form.Write(WriteParameters);
		Else
			CheckPossibilityOfFillingInAfterRecording(Form.Write(WriteParameters), AdditionalParameters);
		EndIf;
		
	Else
		CheckPossibilityOfFillingInAfterRecording(True, AdditionalParameters);
	EndIf;
	
EndProcedure

Procedure CheckPossibilityOfFillingInAfterRecording(RecordingResult, AdditionalParameters) Export
	
	If Not RecordingResult Then
		ShowMessageBox(,NStr("vi = 'Không thể hủy bỏ kết chuyển chứng từ';
							|ru = 'Не удалось отменить проведение документа';
							|en = 'Cannot cancel document posting'; fa = 'Cannot cancel document posting';
							|it = 'Impossibile annullare la registrazione del documento';
							|pl = 'Nie udało się anulować zatwierdzenie dokumentu';
							|tr = 'Belge kaydetme iptal edilemedi'"));
		Return;
	EndIf;
	
	If ValueIsFilled(AdditionalParameters.TabularSection) Then
		AdditionalParameters.TabularSection.Clear();
		AdditionalParameters.Form.Modified = True;
	EndIf;
	
	RunCallback(AdditionalParameters.NotificationAfterVerification, RecordingResult);
	
EndProcedure

#EndRegion

#Region SplittingString

Procedure AddLineBySplitting(TS, FormItem, Count, NotificationAfterSplitting, StringSplittingParameters)
	
	CurrentRow = FormItem.CurrentData;
	NewRow   = TS.Insert(TS.IndexOf(CurrentRow) + 1);
	FillPropertyValues(NewRow, CurrentRow);
	
	NewRow[StringSplittingParameters.FieldNameQuantity]   = Count;
	CurrentRow[StringSplittingParameters.FieldNameQuantity] =
		CurrentRow[StringSplittingParameters.FieldNameQuantity] - Count;
	
	If NotificationAfterSplitting <> Undefined Then
		RunCallback(NotificationAfterSplitting, NewRow);
	EndIf;
	
	FormItem.CurrentRow = NewRow.GetID();
	
EndProcedure

Procedure EnterQuantityToSplit(ProcessingParameters) Export
	
	StringSplittingParameters = ProcessingParameters.StringSplittingParameters;
	
	If StringSplittingParameters.Count = Undefined Then
		Count = ProcessingParameters.FormItem.CurrentData[StringSplittingParameters.FieldNameQuantity];
	Else
		Count = StringSplittingParameters.Count;
	EndIf;
	
	Notification = New CallbackDescription("EnterNumberToSplitAfterEntering", ThisObject, ProcessingParameters);
	ShowInputNumber(Notification, Count, StringSplittingParameters.Title, 15, 3);
	
EndProcedure

Procedure EnterNumberToSplitAfterEntering(Count, ProcessingParameters) Export
	
	NotificationAfterSplitting = ProcessingParameters.NotificationAfterSplitting;
	
	If Count = Undefined Then
		If NotificationAfterSplitting <> Undefined Then
			RunCallback(NotificationAfterSplitting, Undefined);
		EndIf;
		Return;
	EndIf;
	
	StringSplittingParameters = ProcessingParameters.StringSplittingParameters;
	CurrentCount = ProcessingParameters.FormItem.CurrentData[StringSplittingParameters.FieldNameQuantity];
	
	MessageText = Undefined;
	If Count = 0 And Not StringSplittingParameters.AllowZeroCount Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể bằng 0.';
							|ru = 'Количество в новой строке не может быть равно нулю.';
							|en = 'Quantity in a new line should not be equal to zero.'; fa = 'Quantity in a new line should not be equal to zero.';
							|it = 'La quantità nella nuova riga non può essere pari a zero.';
							|pl = 'Ilość w nowym wierszu nie może być równa zeru.';
							|tr = 'Yeni satırdaki sayı sıfıra eşit olamaz.'");
	ElsIf Count = CurrentCount And Not StringSplittingParameters.AllowZeroCount Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới phải khác số lượng trong dòng hiện tại.';
							|ru = 'Количество в новой строке должно отличаться от количества в текущей.';
							|en = 'Quantity in a new line should differ from quantity in the current line.'; fa = 'Quantity in a new line should differ from quantity in the current line.';
							|it = 'La quantità nella nuova riga deve differire dalla quantità nella riga corrente.';
							|pl = 'Ilość w nowym wierszu powinna różnić się od ilości w wierszu bieżącym.';
							|tr = 'Yeni satırdaki miktar, mevcut satırdaki miktardan farklı olmalıdır.'");
	ElsIf Count < 0 And CurrentCount >= 0 Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể âm.';
							|ru = 'Количество в новой строке не может быть отрицательным.';
							|en = 'Quantity in a new line should not be negative.'; fa = 'Quantity in a new line should not be negative.';
							|it = 'La quantità nella nuova riga non può essere negativa.';
							|pl = 'Ilość w nowym wierszu nie może być ujemna.';
							|tr = 'Yeni satırdaki sayı negatif olamaz.'");
	ElsIf Count > 0 And CurrentCount <= 0 Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể dương.';
							|ru = 'Количество в новой строке не может быть положительным.';
							|en = 'Quantity in a new line should not be positive.'; fa = 'Quantity in a new line should not be positive.';
							|it = 'La quantità nella nuova riga non può essere positiva.';
							|pl = 'Ilość w nowym wierszu nie może być dodatnia.';
							|tr = 'Yeni satırdaki sayı pozitif olamaz.'");
	ElsIf Count > CurrentCount And CurrentCount >= 0 Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể lớn hơn số lượng trong dòng hiện tại.';
							|ru = 'Количество в новой строке не может быть больше количества в текущей.';
							|en = 'Quantity in a new line should not differ from quantity in the current line.'; fa = 'Quantity in a new line should not differ from quantity in the current line.';
							|it = 'La quantità nella nuova riga non può essere maggiore della quantità nella riga corrente.';
							|pl = 'Ilość w nowym wierszu nie może być większa od ilości w wierszu bieżącym.';
							|tr = 'Yeni satırdaki miktar, mevcut satırdaki miktardan büyük olamaz.'");
	ElsIf Count < CurrentCount And CurrentCount <= 0 Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể nhỏ hơn số lượng trong dòng hiện tại.';
							|ru = 'Количество в новой строке не может быть меньше количества в текущей.';
							|en = 'Quantity in a new line should not be less than quantity in the current line.'; fa = 'Quantity in a new line should not be less than quantity in the current line.';
							|it = 'La quantità nella nuova riga non può essere inferiore alla quantità nella riga corrente.';
							|pl = 'Ilość w nowym wierszu nie może być mniejsza od ilości w wierszu bieżącym.';
							|tr = 'Yeni satırdaki miktar, mevcut olandaki miktardan az olamaz.'");
	ElsIf StringSplittingParameters.MaximumAllowedValue <> 0 
		And Count > StringSplittingParameters.MaximumAllowedValue Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không cần vượt %1.';
							|ru = 'Количество в новой строке не должно превышать %1.';
							|en = 'The quantity in the new line cannot exceed %1.'; fa = 'The quantity in the new line cannot exceed %1.';
							|it = 'Количество в новой строке не должно превышать %1.';
							|pl = 'The quantity in the new line cannot exceed %1.';
							|tr = 'Yeni satırdaki sayı %1''i geçmemelidir.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageText, StringSplittingParameters.MaximumAllowedValue);
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		Notification = New CallbackDescription("EnterQuantityToSplit", ThisObject, ProcessingParameters);
		ShowMessageBox(Notification, MessageText);
	Else
		AddLineBySplitting(ProcessingParameters.TabularSection, ProcessingParameters.FormItem,
			Count, NotificationAfterSplitting, StringSplittingParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
