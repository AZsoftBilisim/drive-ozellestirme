
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	OnDate = CurrentSessionDate();
	
	SetAvailability(ThisForm);
	
	UpdateList();
	
	FormEvents.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ProductCategory  = Settings.Get("ProductCategory");
	If ValueIsFilled(ProductCategory) Then
		Attribute = Settings.Get("Attribute");
	Else
		Attribute = Undefined;
	EndIf; 
	
	UpdateList();
	
	SetAvailability(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure FilterProductCategoryOnChange(Item)
	
	SetAvailability(ThisForm);
	
	If ValueIsFilled(ProductCategory) Then
	
		FilterProductCategoryWhenChangedOnServer();
		
	Else
		
		Attribute = Undefined;
		UpdateList();
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure FilterAttributeOnChange(Item)
	
	UpdateList();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStandards

&AtClient
Procedure StandardsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Item.CurrentData <> Undefined 
		And Item.CurrentData.Property("Recorder")
		And ValueIsFilled(Item.CurrentData.Recorder) Then
	
		ShowValue(, Item.CurrentData.Recorder);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenAllocationStandards(Command)
	
	OpenForm("Document.SalesPlansAllocationBaseByCategories.ListForm"); 
	
EndProcedure

&AtClient
Procedure OpenStandards(Command)
	
	If Items.Standards.CurrentData <> Undefined 
		And Items.Standards.CurrentData.Property("Recorder")
		And ValueIsFilled(Items.Standards.CurrentData.Recorder) Then
		
		ShowValue(, Items.Standards.CurrentData.Recorder);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure DontUse(Command)
	
	If Items.Standards.SelectedRows.Count() > 0 Then 
		
		ThereIsValidStandard = False;
		For Each SelectedRow In Items.Standards.SelectedRows Do
		
			NormativeStandard = Standards.FindByID(SelectedRow);
			If NormativeStandard <> Undefined
				And ValueIsFilled(NormativeStandard.ProductCategory) 
				And ValueIsFilled(NormativeStandard.Attribute) 
				And NormativeStandard.Valid Then
				
				ThereIsValidStandard = True;
				Break;
				
			EndIf;
		
		EndDo; 
		
		If Not ThereIsValidStandard Then
			
			WarningText = NStr("vi = 'Cần chọn trong danh sách ít nhất một định mức hiện hành.';
								|ru = 'Необходимо выбрать в списке хотя бы один действующий норматив.';
								|en = 'Select at least one active standard in the list.'; fa = 'Select at least one active standard in the list.';
								|it = 'È necessario selezionare dall''elenco almeno un normativo valido.';
								|pl = 'Należy wybrać w liście chociażby jeden ważny normatyw.';
								|tr = 'Listeden en az bir mevcut standart seçmek şart.'");
			ShowMessageBox(, WarningText);
			Return;
			
		Else
		
			QueryText = NStr("vi = 'Thiết lập ""Không sử dụng"" cho định mức đã chọn với ngày %Date%?';
							|ru = 'Установить ""Не использовать"" для выбранных нормативов с %Date%?';
							|en = 'Set ""Do not use"" for the selected standards from %Date%?'; fa = 'Set ""Do not use"" for the selected standards from %Date%?';
							|it = 'Impostare ""Non utilizzare"" per i normativi selezionati dal %Date%?';
							|pl = 'Ustawić ""Не использовать"" dla wybranych normatywów od%Date%?';
							|tr = 'Seçili standartlar için ""Kullanılmayan"" kur %Date% ile?'");
			QueryText = StrReplace(QueryText, "%Date%", Format(OnDate, "DLF=D"));
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Thiết lập ""Không sử dụng""';
													|ru = 'Установить ""Не использовать""';
													|en = 'Set ""Do not use""'; fa = 'Set ""Do not use""';
													|it = 'Impostare ""Non utilizzare""';
													|pl = 'Ustaw ""Не использовать""';
													|tr = '""Kullanma"" kur'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
			
			Notification = New CallbackDescription("NotUseCompletion", ThisObject);
			
			ShowQueryBox(Notification, QueryText, Buttons);
		
		EndIf; 
	Else
		WarningText = NStr("vi = 'Cần chọn trong danh sách ít nhất một định mức hiện hành.';
							|ru = 'Необходимо выбрать в списке хотя бы один действующий норматив.';
							|en = 'Select at least one active standard in the list.'; fa = 'Select at least one active standard in the list.';
							|it = 'È necessario selezionare dall''elenco almeno un normativo valido.';
							|pl = 'Należy wybrać w liście chociażby jeden ważny normatyw.';
							|tr = 'Listeden en az bir mevcut standart seçmek şart.'");
		ShowMessageBox(, WarningText);
	EndIf; 
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("ValidityStartDate", OnDate);
	If ValueIsFilled(ProductCategory) Then
		FillingValues.Insert("ProductCategory", ProductCategory);
	Else
		
		CurrentData = Items.Standards.CurrentData;
		If CurrentData <> Undefined Then
			FillingValues.Insert("ProductCategory", CurrentData.ProductCategory);
		EndIf; 
		
	EndIf; 
	
	If ValueIsFilled(Attribute) Then
		FillingValues.Insert("Attribute", Attribute);
	Else
		
		CurrentData = Items.Standards.CurrentData;
		If CurrentData <> Undefined Then
			FillingValues.Insert("Attribute", CurrentData.Attribute);
		EndIf; 
		
	EndIf; 
	FillingValues.Insert("FillInValues", True);
	FillingValues.Insert("Operation", PredefinedValue("Enum.TransactionsOfStandardsAllocation.SetStandard"));
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	Notification = New CallbackDescription("OpeningOfStandardFormCompletion", ThisObject);
	
	OpenForm("Document.SalesPlansAllocationBaseByCategories.ObjectForm", FormParameters, ThisForm,,,,Notification);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	
EndProcedure

&AtClient
Procedure OpeningOfStandardFormCompletion(Result, AdditionalParameters) Export 
	
	If NewAllocationStandard = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(NewAllocationStandard.Ref) 
		And NewAllocationStandard.Posted
		And ValueIsFilled(NewAllocationStandard.ProductCategory)
		And ValueIsFilled(NewAllocationStandard.Attribute) Then
		
		ProductCategories = Standards.GetItems();
		For Each ProductCategoryElement In ProductCategories Do
			
			If ProductCategoryElement.ProductCategory = NewAllocationStandard.ProductCategory Then
				
				FoundStandard = Undefined;
				ElementsStandards = ProductCategoryElement.GetItems();
				For Each ElementStandard In ElementsStandards Do
					If ElementStandard.Attribute = NewAllocationStandard.Attribute Then
						FoundStandard = ElementStandard;
						Break;
					EndIf;
				EndDo;
				If FoundStandard = Undefined Then
					ElementStandard = ElementsStandards.Add();
				Else
					ElementStandard = FoundStandard;
				EndIf; 
				
				ElementStandard.NormativeStandard                  = NewAllocationStandard.Ref;
				ElementStandard.Recorder               = NewAllocationStandard.Ref;
				ElementStandard.ProductCategory         = NewAllocationStandard.ProductCategory;
				ElementStandard.Attribute                  = NewAllocationStandard.Attribute;
				ElementStandard.Period                    = NewAllocationStandard.ValidityStartDate;
				ElementStandard.ByItemVariants         = NewAllocationStandard.FillingVariant = 2;
				ElementStandard.ProductCategoryDetails = NewAllocationStandard.Attribute;
				ElementStandard.Valid                 = True;
				
				If NewAllocationStandard.FillingVariant = 2 Then
					ElementStandard.PictureIndex = 2;
				Else
					ElementStandard.PictureIndex = 1;
				EndIf; 
				Break;
			EndIf; 
		EndDo; 
	EndIf;
	
	NewAllocationStandard = Undefined;
	
EndProcedure

&AtServer
Procedure UpdateList()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductCategories.Ref AS ProductCategory,
	|	StandardsForDistributionOfSlices.Attribute,
	|	StandardsForDistributionOfSlices.NormativeStandard,
	|	StandardsForDistributionOfSlices.Valid,
	|	StandardsForDistributionOfSlices.ByItemVariants,
	|	StandardsForDistributionOfSlices.Period,
	|	StandardsForDistributionOfSlices.Recorder,
	|	ProductCategories.DeletionMark AS ProductCategoryDeletionMark
	|FROM
	|	Catalog.ProductCategories AS ProductCategories
	|		LEFT JOIN InformationRegister.StandardsOfSalesPlanAllocationByCategories.SliceLast(
	|				&OnDate,
	|				&FilterProductCategory1
	|					AND &FilterAttribute) AS StandardsForDistributionOfSlices
	|		ON ProductCategories.Ref = StandardsForDistributionOfSlices.ProductCategory
	|WHERE
	|	NOT ProductCategories.IsFolder
	|	AND &FilterProductCategory2
	|TOTALS BY
	|	ProductCategory";
	
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("Attribute", Attribute);
	Query.SetParameter("ProductCategory", ProductCategory);
	
	FilterProductCategory1 = "TRUE";
	FilterProductCategory2 = "";
	FilterAttribute = "";
	
	If ValueIsFilled(ProductCategory) Then
	
		FilterProductCategory1 = "ProductCategory = &ProductCategory";
		FilterProductCategory2 = "AND ProductCategories.Ref = &ProductCategory";
	
	EndIf; 
	If ValueIsFilled(Attribute) Then
	
		FilterAttribute = "AND Attribute = &Attribute";
	
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&FilterProductCategory1", FilterProductCategory1);
	Query.Text = StrReplace(Query.Text, "AND &FilterProductCategory2", FilterProductCategory2);
	Query.Text = StrReplace(Query.Text, "AND &FilterAttribute", FilterAttribute);
	
	QueryResult = Query.Execute();
	
	SelectionProductCategory = QueryResult.Select(QueryResultIteration.ByGroups);
	
	ProductCategories = Standards.GetItems();
	ProductCategories.Clear();
	
	While SelectionProductCategory.Next() Do
		
		NewLineProductCategory = ProductCategories.Add();
		FillPropertyValues(NewLineProductCategory, SelectionProductCategory);
		NewLineProductCategory.ProductCategoryDetails = NewLineProductCategory.ProductCategory;
		
		SelectionDetailRecords = SelectionProductCategory.Select();
		Attributes =  NewLineProductCategory.GetItems();
		While SelectionDetailRecords.Next() Do
			
			If SelectionDetailRecords.ProductCategoryDeletionMark Then
				NewLineProductCategory.PictureIndex = 3;
			Else
				NewLineProductCategory.PictureIndex = 0;
			EndIf; 
			
			If Not ValueIsFilled(SelectionDetailRecords.Attribute) Then
				Continue;
			EndIf; 
			
			NewLineProps = Attributes.Add();
			FillPropertyValues(NewLineProps, SelectionDetailRecords);
			NewLineProps.ProductCategoryDetails = NewLineProps.Attribute;
			
			If NewLineProps.ByItemVariants Then
				If SelectionDetailRecords.Valid Then
					NewLineProps.PictureIndex = 2;
				Else
					NewLineProps.PictureIndex = 5;
				EndIf; 
			Else
				If NewLineProps.Valid Then
					NewLineProps.PictureIndex = 1;
				Else
					NewLineProps.PictureIndex = 4;
				EndIf; 
			EndIf; 
			
		EndDo;
	EndDo;
	
	Items.Standards.InitialTreeView = InitialTreeView.NoExpand;
	Items.Standards.InitialTreeView = InitialTreeView.ExpandAllLevels;
	
EndProcedure 

&AtServer
Procedure FilterProductCategoryWhenChangedOnServer()

	FillInListOfBankingDetails();
	Items.Standards.InitialTreeView = InitialTreeView.ExpandAllLevels;
	UpdateList();

EndProcedure 

&AtClientAtServerNoContext
Procedure SetAvailability(Form)

	If ValueIsFilled(Form.ProductCategory) Then
	
		Form.Items.FilterAttribute.Enabled = True;
	
	Else
	
		Form.Items.FilterAttribute.Enabled = False;
	
	EndIf; 

EndProcedure

&AtServer
Procedure FillInListOfBankingDetails()

	AttributesStructure1 = Documents.SalesPlansAllocationBaseByCategories.GetDetailsForRegulations();
	
	Items.FilterAttribute.ChoiceList.Clear();
	For Each KeyValue In AttributesStructure1 Do
		Items.FilterAttribute.ChoiceList.Add(KeyValue.Key, KeyValue.Value.Presentation);
	EndDo; 
	
	ListOfAdditionalBankingDetails = Documents.SalesPlansAllocationBaseByCategories.GetAdditionalDetailsForRegulations(ProductCategory);
	
	For Each ListItem In ListOfAdditionalBankingDetails Do
		Items.FilterAttribute.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;

EndProcedure 

&AtClient
Procedure NotUseCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		
		TotalCount1 = Items.Standards.SelectedRows.Count();
		ProcessedItemsCount = CreateRegulatoryBlockingDocumentsOnServer(OnDate);
		
		MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% / %TotalCount1% được chọn trong danh sách định mức đã đặt phong tỏa sử dụng.';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке нормативов установлена блокировка использования.';
							|en = 'Usage is blocked for %ProcessedItemsCount% out of %TotalCount1% selected in the standard list.'; fa = 'Usage is blocked for %ProcessedItemsCount% out of %TotalCount1% selected in the standard list.';
							|it = 'Per %ProcessedItemsCount% dal %TotalCount1% evidenziati nell''elenco dei normativi è impostato il blocco di utilizzo.';
							|pl = 'Dla %ProcessedItemsCount% z %TotalCount1% wybranych w liście normatywów ustawiono blokowanie używania.';
							|tr = '%TotalCount1% kaynağından %ProcessedItemsCount% için standartlar listesinde vurgulanan standartların kullanımını engelleyecek şekilde ayarlanmıştır.'");
		MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ProcessedItemsCount);
		MessageText = StrReplace(MessageText, "%TotalCount1%",        TotalCount1);
		
		TitleText = NStr("vi = 'Đã đặt phong tỏa định mức';
						|ru = 'Блокировка норматива установлена';
						|en = 'Standard lock is set'; fa = 'Standard lock is set';
						|it = 'Il blocco del normativo è stato installato';
						|pl = 'Ustawiono blokowanie normatywu';
						|tr = 'Standardın kilitlenmesi kuruldu'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf; 
	
EndProcedure

&AtServer
Function CreateRegulatoryBlockingDocumentsOnServer(ValidityStartDate)
	
	ObjectCount = 0;
	For Each RowSelected In Items.Standards.SelectedRows Do
		
		NormativeStandard = Standards.FindByID(RowSelected);
		If NormativeStandard = Undefined 
			Or Not ValueIsFilled(NormativeStandard.ProductCategory) 
			Or Not ValueIsFilled(NormativeStandard.Attribute)
			Or Not NormativeStandard.Valid Then
			Continue;
		EndIf; 
		
		Object = Documents.SalesPlansAllocationBaseByCategories.CreateDocument();
		Object.Date = OnDate;
		If ValueIsFilled(NormativeStandard.Period) And NormativeStandard.Period = ValidityStartDate Then
			Object.ValidityStartDate = EndOfDay(ValidityStartDate) + 1;
			Object.Comment = NStr("vi = 'Đã đặt phong tỏa tại ngày tiếp theo vì trùng với ngày bắt đầu có hiệu lực định mức.';
									|ru = 'Блокировка установлена следующей датой т.к. совпадает с датой начала действия норматива.';
									|en = 'Lock is set for the next date since the date coincides with the standard effective date.'; fa = 'Lock is set for the next date since the date coincides with the standard effective date.';
									|it = 'Il blocco è installato con la data successiva perché coincide con la data di inizio di validità del normativo.';
									|pl = 'Blokowanie jest ustawione z następną datą, ponieważ zbiega się z datą początku ważności normatywu.';
									|tr = 'Kilitleme işlemi standart eyleminin başlangıç tarihiyle çakıştığı için bir sonraki tarihe ayarlandı.'");
		Else
			Object.ValidityStartDate = ValidityStartDate;
		EndIf; 
		
		Object.Operation = Enums.TransactionsOfStandardsAllocation.StandardLock;
		Object.ProductCategory = NormativeStandard.ProductCategory;
		Object.Attribute = NormativeStandard.Attribute;
		
		Object.EmployeeResponsible = Users.CurrentUser();
		
		Try
		
			Object.Write(DocumentWriteMode.Posting);
			ObjectCount = ObjectCount + 1;
		
		Except
			WriteLogEvent(NStr("vi = 'Dữ liệu';
								|ru = 'Данные';
								|en = 'Data'; fa = 'داده';
								|it = 'Dati';
								|pl = 'Data';
								|tr = 'Veriler'", CommonClientServer.DefaultLanguageCode()) + "." 
				+ NStr("vi = 'Tiến hành';
						|ru = 'Проведение';
						|en = 'Posting'; fa = 'ثبت در دفاتر';
						|it = 'Svolgimento';
						|pl = 'Posting';
						|tr = 'Kaydetme'", CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error, 
				Documents.SalesPlansAllocationBaseByCategories,, 
				ErrorDescription());
		EndTry; 
	
	EndDo; 
	
	UpdateList();
	
	Return ObjectCount;
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_OnDate" Then
		OnDateOnChange(Items.OnDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
