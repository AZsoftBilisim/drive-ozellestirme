
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("Products",Products);
	ProductKind = Common.ObjectAttributeValue(Products,"ProductKind");
	
	TitleText = NStr("vi = 'Chứng nhận mặt hàng (%Owner%)';
					|ru = 'Сертификаты номенклатуры (%Owner%)';
					|en = 'Quality certificates (%Owner%)'; fa = 'Quality certificates (%Owner%)';
					|it = 'Certificato di articolo (%Owner%)';
					|pl = 'Certyfikaty towarów (%Owner%)';
					|tr = 'Kalite belgeleri (%Owner%)'");
	TitleText = StrReplace(TitleText, "%Owner%", String(Products));
	
	AutoTitle = False;
	Title     = TitleText;
	
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"ProductKind",
		ProductKind);
		
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"Products",
		Products);
	
	If Common.ObjectAttributeValue(Products,"UseVariants") =
		Enums.ItemVariantsUsageOptions.DontUse Then
		Items.QualityCertificatesCharacteristic.Visible = False;
	EndIf;
	
	If Not Common.ObjectAttributeValue(ProductKind,"KeepAccountingByBatch") Then
		Items.QualityCertificatesSeries.Visible = False;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "CreateItemCertificates",
			"Visible", AccessRight("Insert", Metadata.Catalogs.QualityCertificates));
	TMCommonUseClientServer.SetFormItemProperty(Items, "CopyItemCertificates",
			"Visible", AccessRight("Insert", Metadata.Catalogs.QualityCertificates));
	TMCommonUseClientServer.SetFormItemProperty(Items, "ItemCertificatesChange",
			"Visible", AccessRight("Update", Metadata.Catalogs.QualityCertificates));
	TMCommonUseClientServer.SetFormItemProperty(Items, "ItemCertificatesMarkForDeletion",
			"Visible", AccessRight("InteractiveSetDeletionMark", Metadata.Catalogs.QualityCertificates));
	TMCommonUseClientServer.SetFormItemProperty(Items, "SelectCertificates",
			"Visible", AccessRight("Edit", Metadata.Catalogs.QualityCertificates));
	
	TypesArray = Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	Items.CertificateType.ChoiceList.LoadValues(TypesArray);
	
	If OnlyValidAsOfTheDate Then
		Items.Date.Enabled = True;
	Else
		Items.Date.Enabled = False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.Catalogs.QualityCertificates) Then
		Items.GroupCommandBarSetStatus.Enabled = False;
	EndIf;
	
	Date = CurrentSessionDate();
	
	ProductsLocalization.WhenCreatingOnServer_NomenclatureCertificates_ListForm(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarProductCertificates;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_QualityCertificate" Then
		
		TypesArray = CreateListToSelectCertificateTypes();
		Items.CertificateType.ChoiceList.LoadValues(TypesArray);
		Items.QualityCertificates.Refresh();
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CertificateTypeOnChange(Item)
			
	CommonClientServer.SetDynamicListFilterItem(
		QualityCertificates,
		"CertificateType",
		CertificateType,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(CertificateType));
			
EndProcedure

&AtClient
Procedure CertificateTypeAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	TypesArray = GenerateListOfTypes(Text);
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(TypesArray);

EndProcedure

&AtClient
Procedure OnlyValidAsOfTheDateOnChange(Item)
	
	If OnlyValidAsOfTheDate Then
		Items.Date.Enabled = True;
	Else	
		Items.Date.Enabled = False;
	EndIf;
	
	SetSelectionForOnlyThoseValidOnDate();	
		
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetSelectionForOnlyThoseValidOnDate();
	
EndProcedure

&AtClient
Procedure WhenChangingAttributesOfForm(Item)
	
	ProductsClientLocalization.WhenChangingDetails_CertificatesOfItem_FormOfList(Item, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQualityCertificates

&AtClient
Procedure QualityCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If ProductsClientLocalization.ChoosingStatusOfRosaccreditation(Field, Items) Then
		ProductsClientLocalization.WhenChoosingStatusOfRosaccreditation(Item, StandardProcessing);
	Else
		TMCommonUseClient.ChangeElement(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure QualityCertificatesOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure QualityCertificatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Copy Then
		CopyItemCertificates(Undefined);
	Else
		CreateItemCertificates(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure QualityCertificatesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	ItemCertificatesChange(Undefined);
	
EndProcedure

&AtClient
Procedure QualityCertificatesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	ItemCertificatesMarkForDeletion(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetCurrentStatus(Command)
	
	ProductsClient.SetStatusOfNomenclatureCertificates(
		ThisObject,
		Items.QualityCertificates,
		PredefinedValue("Enum.StatusesOfQualityCertificates.Valid_"));
	
EndProcedure

&AtClient
Procedure SetStatusNotValid(Command)
	
	ProductsClient.SetStatusOfNomenclatureCertificates(
		ThisObject,
		Items.QualityCertificates,
		PredefinedValue("Enum.StatusesOfQualityCertificates.Inactive"));
	
EndProcedure

&AtClient
Procedure CreateItemCertificates(Command)
	
	FormParameters = New Structure();	
	FormParameters.Insert("Products", Products);
	FormParameters.Insert("CertificateType", CertificateType);	
	
	OpenForm("Catalog.QualityCertificates.Form.ItemForm", FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure CopyItemCertificates(Command)

	CurrentRow = Items.QualityCertificates.CurrentData;
	If CurrentRow <> Undefined Then	
		FormParameters = New Structure("CopyingValue", CurrentRow.Ref);
		OpenForm("Catalog.QualityCertificates.ObjectForm", FormParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ItemCertificatesChange(Command)
	
	CurrentRow = Items.QualityCertificates.CurrentData;
	If CurrentRow <> Undefined Then	
		FormParameters = New Structure("Key", CurrentRow.Ref);
		OpenForm("Catalog.QualityCertificates.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ItemCertificatesMarkForDeletion(Command)
	
	CurrentRow = Items.QualityCertificates.CurrentData;
	If CurrentRow <> Undefined Then	
		
		QuestionTemplate = ?(CurrentRow.DeletionMark,
			NStr("vi = 'Bỏ dấu xóa ""%1""?';
				|ru = 'Снять с ""%1"" пометку на удаление?';
				|en = 'Clear mark for deletion for ""%1""?'; fa = 'Clear mark for deletion for ""%1""?';
				|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
				|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
				|tr = '""%1"" için silme işareti kaldırılsın mı?'"),
			NStr("vi = 'Đặt dấu xóa ""%1""?';
				|ru = 'Пометить ""%1"" на удаление?';
				|en = 'Mark ""%1"" for deletion?'; fa = 'Mark ""%1"" for deletion?';
				|it = 'Contrassegnare ""%1"" per cancellazione?';
				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
				|tr = '""%1"" silinmek üzere işaretlensin mi?'"));
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionTemplate,
		CurrentRow.Ref);
		
		ShowQueryBox(New CallbackDescription("ItemCertificatesMarkForDeletionCompletion", ThisObject, New Structure("CurrentRow", CurrentRow)), QueryText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCertificates(Command)
	
	OpenForm("Catalog.QualityCertificates.Form.CertificateChoiceForm", New Structure ("Products", Products));
	
EndProcedure

&AtClient
Procedure OpenImage(Command)
	
	ClearMessages();
	
	CurrentRow = Items.QualityCertificates.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.IsFolder Then
		MessageText = NStr("vi = 'Đối với nhóm ""%1"" không cần tiến hành ghi nhận hình ảnh của chứng nhận';
							|ru = 'Для группы ""%1"" не требуется ведение учета изображений сертификатов';
							|en = 'There is no need to keep records of certificate images for the %1 group'; fa = 'There is no need to keep records of certificate images for the %1 group';
							|it = 'There is no need to keep records of certificate images for the %1 group';
							|pl = 'There is no need to keep records of certificate images for the %1 group';
							|tr = '""%1"" grubu için sertifika resimlerinin muhasebesini tutmak gerekli değildir'");
		MessageText = StrTemplate(MessageText, String(CurrentRow.Ref));
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	ReturnStructure = OpenImageOnServer(CurrentRow.Ref);
	
	If ReturnStructure.Result = "NoImages" Then
		MessageText = NStr("vi = 'Đối với chứng nhận mặt hàng ""%Certificate%"" không có hình ảnh để xem trước';
							|ru = 'Для сертификата номенклатуры ""%Certificate%"" отсутствует изображение для просмотра';
							|en = 'There is no image for quality certificate ""%Certificate%""'; fa = 'There is no image for quality certificate ""%Certificate%""';
							|it = 'Per il certificato di articolo""%Certificate%"" manca l''immagine per la visualizzazione';
							|pl = 'Dla certyfikatu ""%Certificate%"" brak obrazu do przeglądania';
							|tr = 'Kalite belgesi için ""%Certificate%"" önizleme görüntüsü yok'");
		MessageText = StrReplace(MessageText, "%Certificate%", CurrentRow.Ref);
		
		CommonClient.MessageToUser(MessageText);
	ElsIf ReturnStructure.Result = "OneImage" Then
		FilesOperationsClient.OpenFile(
			FilesOperationsInternalServerCall.GetFileData(
			ReturnStructure.AttachedFile,
			UUID));
	Else
		ChoiceParameters		= New Structure("FileOwner, CloseOnChoice, ChoiceMode",
												CurrentRow.Ref, True, True);
		CallbackDescription	= New CallbackDescription("OpenImageCompletion", ThisObject);
		
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles",
					ChoiceParameters,
					,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteFormCommand(Command)
	
	ProductsClientLocalization.ExecuteCommand_NomenclatureCertificates_ListForm(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QualityCertificatesCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QualityCertificates.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả đặc tính>';
													|ru = '<для всех характеристик>';
													|en = '<for all variants>'; fa = '<برای همه گونه‌ها>';
													|it = '<comune per tutte le caratteristiche>';
													|pl = '<dla wszystkich charakterystyk>';
													|tr = '<tüm varyantlar için>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QualityCertificatesSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QualityCertificates.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả sê-ri>';
													|ru = '<для всех серий>';
													|en = '<for all batches>'; fa = '<برای همه بچ‌ها>';
													|it = '<comune per tutte le serie>';
													|pl = '<dla wszystkich serii>';
													|tr = '<tüm partiler için>'"));

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QualityCertificatesValidTo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QualityCertificates.Permanent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
		
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочный>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<indeterminato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
	//
	ProductsLocalization.SetConditionalAppearanceOfListOfCertificatesOfNomenclature(ThisObject);
	
EndProcedure

&AtClient
Procedure SetSelectionForOnlyThoseValidOnDate()
	
	UsingSelection = OnlyValidAsOfTheDate
							And ValueIsFilled(Date);
	
	GroupOperatesUnder = CommonClientServer.CreateFilterItemGroup(
										TMCommonUseClientServer.GetDynamicListSelection(QualityCertificates).Items,
										"GroupOperatesUnder",
										DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.SetFilterItem(GroupOperatesUnder,
														"Status",
														PredefinedValue("Enum.StatusesOfQualityCertificates.Valid_"),
														DataCompositionComparisonType.Equal,
														"PickingByStatuses",
														UsingSelection);
	
	GroupSelectionByDate = CommonClientServer.CreateFilterItemGroup(
							GroupOperatesUnder,
							"GroupSelectionByDate",
							DataCompositionFilterItemsGroupType.OrGroup);
	
	GroupSelectionByExpirationDate = CommonClientServer.CreateFilterItemGroup(
									GroupSelectionByDate,
									"GroupSelectionByExpirationDate",
									DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.SetFilterItem(GroupSelectionByExpirationDate,
														"StartDateOfValidityPeriod",
														Date,
														DataCompositionComparisonType.LessOrEqual,
														"SelectionByStartDateOfValidityPeriod",
														UsingSelection);
	
	CommonClientServer.SetFilterItem(GroupSelectionByExpirationDate,
														"ValidTo",
														Date,
														DataCompositionComparisonType.GreaterOrEqual,
														"SelectionByExpirationDate",
														UsingSelection);
	
	CommonClientServer.SetFilterItem(GroupSelectionByDate,
														"Permanent",
														True,
														DataCompositionComparisonType.Equal,
														"SelectionByDateIsIndefinite",
														UsingSelection);
	
EndProcedure

&AtServer
Procedure SetCertificateDeletionMark(CertificateReference, Check)
	
	CertificateObject = CertificateReference.GetObject();
	CertificateObject.SetDeletionMark(Check);	
	CertificateObject.Write();
	
EndProcedure

// Parameters:
// 	QuestionResult - DialogReturnCode - 
// 	AdditionalParameters - Structure - Contains:
//		* CurrentRow - FormDataStructure - 
&AtClient
Procedure ItemCertificatesMarkForDeletionCompletion(QuestionResult, AdditionalParameters) Export
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	Response = QuestionResult; 
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SetCertificateDeletionMark(CurrentRow.Ref,Not CurrentRow.DeletionMark);
	Items.QualityCertificates.Refresh();
	
EndProcedure

&AtClient
Procedure OpenImageCompletion(Result, AdditionalParameters) Export
	
	SelectionValue = Result;
	
	If ValueIsFilled(SelectionValue) Then
		FilesOperationsClient.OpenFile(
			FilesOperationsInternalServerCall.GetFileData(
			SelectionValue,
			UUID));
	EndIf;
	
EndProcedure

&AtServer
Function OpenImageOnServer(QualityCertificate);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(QualityCertificatesAttachedFiles.Ref) AS AttachedFile,
	|	COUNT(DISTINCT QualityCertificatesAttachedFiles.Ref) AS FilesCount,
	|	QualityCertificatesAttachedFiles.FileOwner
	|FROM
	|	Catalog.QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|WHERE
	|	QualityCertificatesAttachedFiles.FileOwner = &FileOwner
	|	AND QualityCertificatesAttachedFiles.DeletionMark = FALSE
	|
	|GROUP BY
	|	QualityCertificatesAttachedFiles.FileOwner";
	Query.SetParameter("FileOwner", QualityCertificate);
	
	Selection = Query.Execute().Select();

	ReturnStructure = New Structure;
	
	If Selection.Next() Then
		If Selection.FilesCount > 1 Then
			ReturnStructure.Insert("Result", "ArrayOfImages");
		ElsIf Selection.FilesCount = 1 Then
			ReturnStructure.Insert("Result", 			"OneImage");
			ReturnStructure.Insert("AttachedFile",	Selection.AttachedFile);
		EndIf;
	Else
		ReturnStructure.Insert("Result", "NoImages");
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServerNoContext
Function GenerateListOfTypes(Text)
	
	Return Catalogs.QualityCertificates.AutomaticSelectionOfCertificateTypes(Text);
	
EndFunction

&AtServerNoContext
Function CreateListToSelectCertificateTypes()
	
	Return Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.QualityCertificates);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.QualityCertificates, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.QualityCertificates);
EndProcedure
// End StandardSubsystems.AttachableCommands

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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
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
