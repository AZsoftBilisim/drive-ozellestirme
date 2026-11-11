#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
	ExclusionDocuments = ExclusionDocuments();
	NamesOfDocumentsToBeChecked = NamesOfDocumentsToBeChecked();
	
	ChoiceList = CheckValueSelectionList();
	CommonClientServer.SupplementTable(ChoiceList, Items.TreeOfDocumentsToBeCheckedCheckValue.ChoiceList);
	Items.TreeOfDocumentsBeingCheckedIsDefaultValue.Title = ChoiceList.Get(3);
	
	ReadOnly = AccessRight("Update", Metadata.InformationRegisters.SettingsOfDocumentCheckExceptions);
	ObjectsGroupMethod = "ByKinds";
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillInDocumentTree();
	
	FormEventsClient.OnOpen(ThisObject, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Exit Then
		Cancel = True;
		WarningText = 
		NStr("vi = 'Các tùy chỉnh loại trừ chứng từ kiểm tra đã thay đổi, nhưng chưa được lưu lại. Để những thay đổi có hiệu lực, cần lưu lại tùy chỉnh.';
			|ru = 'Настройки исключений проверяемых документов были изменены, но не сохранены. Для того, чтобы изменения вступили в силу следует сохранить настройки.';
			|en = 'The exception settings of documents under check were changed but not saved. To apply the changes, save the settings.'; fa = 'The exception settings of documents under check were changed but not saved. To apply the changes, save the settings.';
			|it = 'Настройки исключений проверяемых документов были изменены, но не сохранены. Для того, чтобы изменения вступили в силу следует сохранить настройки.';
			|pl = 'The exception settings of documents under check were changed but not saved. To apply the changes, save the settings.';
			|tr = 'Kontrol edilen belgelerin istisna ayarları değiştirilmiş ancak kaydedilmemiştir. Değişikliklerin etkili olması için ayarların kaydedilmesi gerekmektedir.'");
		Return;
	EndIf;
		
	If Modified Then
		Cancel = True;
		QueryText = NStr("vi = 'Tùy chỉnh loại trừ chứng từ kiểm tra đã thay đổi. Lưu thay đổi?';
						|ru = 'Настройки исключений проверяемых документов были изменены. Сохранить изменения?';
						|en = 'The exception settings of documents under check were changed. Do you want to save the changes?'; fa = 'The exception settings of documents under check were changed. Do you want to save the changes?';
						|it = 'Настройки исключений проверяемых документов были изменены. Сохранить изменения?';
						|pl = 'The exception settings of documents under check were changed. Do you want to save the changes?';
						|tr = 'Kontrol edilen belgelerin istisna ayarları değiştirildi. Değişiklikler kaydedilsin mi?'");
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), QueryText, QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	EndIf;
	
EndProcedure
#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CheckOnChange(Item)
	
	Modified = True;
	OnMarkTreeItem(CurrentItem.CurrentData);
	
EndProcedure

&AtClient
Procedure ChoiceModeOnChange(Item)
	
	If Modified Then
		ExclusionDocuments.Clear();
		UpdateExceptionDocumentsRecursively(TreeOfDocumentsToBeChecked.GetItems());
	EndIf;
	
	Items.Presentation.Title = ?(ObjectsGroupMethod = "BySections", NStr("vi = 'Phân hệ / Dạng chứng từ';
																		|ru = 'Раздел / Вид документа';
																		|en = 'Section / Document kind'; fa = 'Section / Document kind';
																		|it = 'Раздел / Вид документа';
																		|pl = 'Section / Document kind';
																		|tr = 'Belge bölümü / Türü'"), NStr("vi = 'Dạng chứng từ';
																												|ru = 'Вид документа';
																												|en = 'Document kind'; fa = 'نوع سند';
																												|it = 'Tipologia di documento';
																												|pl = 'Rodzaj dokumentu';
																												|tr = 'Belge türü'"));
	FillInDocumentTree();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ProcessRecord(Command)
	
	If Modified Then
		ExclusionDocuments.Clear();
		UpdateExceptionDocumentsRecursively(TreeOfDocumentsToBeChecked.GetItems());
		SaveExceptionSettings(ExclusionDocuments);
		Modified = False;
	EndIf;
	
	If Command.Name = "WriteAndClose" Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetValidationValue(Command)
	
	For Each RowID In Items.TreeOfDocumentsToBeChecked.SelectedRows Do
		RowData = Items.TreeOfDocumentsToBeChecked.RowData(RowID);
		NewValidationValue = Check(Command.Name);
		If RowData.CheckValue <> NewValidationValue Then
			RowData.CheckValue = NewValidationValue;
			Modified = True;
		EndIf;
		OnMarkTreeItem(RowData);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items["TreeOfDocumentsToBeChecked"].Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "TreeOfDocumentsToBeChecked.IsSubsection", True, DataCompositionComparisonType.Equal);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.FunctionsPanelSectionColor);
	
	ChoiceList = CheckValueSelectionList();
	For Each ChoiceItem In ChoiceList Do
		Item = ConditionalAppearance.Items.Add();
		DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items["TreeOfDocumentsToBeCheckedCheckValue"].Name);
		DataCompositionClientServer.AddFilter(Item.Filter, "TreeOfDocumentsToBeChecked.CheckValue", ChoiceItem.Value, DataCompositionComparisonType.Equal);
		Item.Appearance.SetParameterValue("Text", ChoiceItem.Presentation);
	EndDo;
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items["TreeOfDocumentsToBeCheckedCheckValue"].Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "TreeOfDocumentsToBeChecked.CheckValue", 5, DataCompositionComparisonType.Equal);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nhiều phương án';
													|ru = 'Несколько вариантов';
													|en = 'Several options'; fa = 'Several options';
													|it = 'Несколько вариантов';
													|pl = 'Several options';
													|tr = 'Birden fazla seçenek'"));
	
EndProcedure

#Region FillingTree

&AtClient
Procedure FillInDocumentTree()
	
	ExpandableRowIds = New Array;
	FillInDocumentTreeOnServer(ExpandableRowIds);
	
	For Each RowID In ExpandableRowIds Do
		Items.TreeOfDocumentsToBeChecked.Expand(RowID);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInDocumentTreeOnServer(ExpandableRowIds)
	
	If ObjectsGroupMethod = "BySections" Then
		FillInTreeOfDocumentsToBeCheckedBySections();
	Else
		FillInTreeOfDocumentsToBeChecked();
	EndIf;
	
	If TreeOfDocumentsToBeChecked.GetItems().Count() < 1 Then
		Return;
	EndIf;
	
	RootId = TreeOfDocumentsToBeChecked.GetItems()[0].GetID();
	ExpandableRowIds.Add(RootId);
	
EndProcedure

&AtServer
Procedure FillInTreeOfDocumentsToBeChecked()
	
	TreeOfDocumentsToBeChecked.GetItems().Clear();
	
	VerifiableDocuments = TreeOfDocumentsToBeChecked.GetItems().Add();
	VerifiableDocuments.Name = "VerifiableDocuments";
	VerifiableDocuments.FullName = NStr("vi = 'Chứng từ kiểm tra';
										|ru = 'Проверяемые документы';
										|en = 'Documents under check'; fa = 'Documents under check';
										|it = 'Проверяемые документы';
										|pl = 'Documents under check';
										|tr = 'Kontrol edilen belgeler'");
	VerifiableDocuments.Presentation = VerifiableDocuments.FullName;
	VerifiableDocuments.Picture = PictureLib.Document;
	
	OutputCollection(VerifiableDocuments, NamesOfDocumentsToBeChecked.UnloadValues());
	
	VerifiableDocuments.CheckValue = CheckMarkValueRelativeToNestedItems(VerifiableDocuments);
	
EndProcedure

&AtServer
Procedure FillInTreeOfDocumentsToBeCheckedBySections()
	
	TreeOfDocumentsToBeChecked.GetItems().Clear();
	
	Branch1 = TreeOfDocumentsToBeChecked.GetItems().Add();
	Branch1.Name = "VerifiableDocuments";
	Branch1.Presentation = NStr("vi = 'Chứng từ kiểm tra';
								|ru = 'Проверяемые документы';
								|en = 'Documents under check'; fa = 'Documents under check';
								|it = 'Проверяемые документы';
								|pl = 'Documents under check';
								|tr = 'Kontrol edilen belgeler'");
	
	DocumentsInTree = New Array;
	
	OutputCollection(Branch1, Metadata.Subsystems, DocumentsInTree);
	
	MissingVerifiableDocuments = CommonClientServer.ArraysDifference(NamesOfDocumentsToBeChecked.UnloadValues(), DocumentsInTree);
	
	If MissingVerifiableDocuments.Count() Then
		
		// Some documents may not be included in any of the sections (since the section is not displayed in the command interface), we will display them separately:
		NewBranch = Branch1.GetItems().Add();
		NewBranch.Name = "DocumentsWithoutSection";
		NewBranch.FullName = NStr("vi = 'Chứng từ không có phân hệ';
									|ru = 'Документы без раздела';
									|en = 'Documents without a section'; fa = 'Documents without a section';
									|it = 'Документы без раздела';
									|pl = 'Documents without a section';
									|tr = 'Bölümsüz belgeler'");
		NewBranch.Presentation = NewBranch.FullName;
		NewBranch.Picture = PictureLib.DoQueryBox;
		
		OutputCollection(NewBranch, MissingVerifiableDocuments);
		
		NewBranch.CheckValue = CheckMarkValueRelativeToNestedItems(NewBranch);
		
	EndIf;
	
	Branch1.CheckValue = CheckMarkValueRelativeToNestedItems(Branch1);
	
EndProcedure

&AtServer
Procedure OutputCollection(Val Branch1, Val MetadataObjectCollection, SelectedDocuments = Undefined)
	
	For Each CollectionItem In MetadataObjectCollection Do
		
		MetadataObject = ?(TypeOf(CollectionItem) = Type("String"), Documents[CollectionItem].EmptyRef().Metadata(), CollectionItem);
		
		If TypeOf(Branch1) = Type("FormDataTreeItem") And MetadataObject.FullName() = Branch1.FullName Then
			Continue;
		EndIf;
		
		If SelectedDocuments <> Undefined Then
			If Not MetadataObjectAvailable(MetadataObject) Then
				Continue;
			EndIf;
		EndIf;
		
		NewBranch = Branch1.GetItems().Add();
		NewBranch.Name = MetadataObject.Name;
		NewBranch.FullName = MetadataObject.FullName();
		NewBranch.Presentation = MetadataObject.Presentation();
		NewBranch.Picture = PictureInInterface(MetadataObject);
		
		If IsSubsystem(MetadataObject) Then
			OutputCollection(NewBranch, MetadataObject.Content, SelectedDocuments);
			OutputCollection(NewBranch, MetadataObject.Subsystems, SelectedDocuments);
			NewBranch.IsSubsection = MetadataObjectCollection <> Metadata.Subsystems;
		ElsIf Common.IsDocumentJournal(MetadataObject) Then
			OutputCollection(NewBranch, MetadataObject.RegisteredDocuments, SelectedDocuments);
		EndIf;
		
		If IsSubsystem(MetadataObject) And NewBranch.GetItems().Count() = 0 Then
			IndexOf = Branch1.GetItems().IndexOf(NewBranch);
			Branch1.GetItems().Delete(IndexOf);
		ElsIf IsSubsystem(MetadataObject) Then
			NewBranch.CheckValue = CheckMarkValueRelativeToNestedItems(NewBranch);
		Else
			NewBranch.CheckValue = CommonClientServer.StructureProperty(ExclusionDocuments, NewBranch.Name, Check("Default"));
			If SelectedDocuments <> Undefined Then
				SelectedDocuments.Add(NewBranch.Name);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region ItemsMark

&AtClientAtServerNoContext
Procedure OnMarkTreeItem(TreeItem)
	
	NestedItems = TreeItem.GetItems();
	If NestedItems.Count() Then
		MarkNestedItemsRecursively(NestedItems, TreeItem.CheckValue);
	EndIf;
	
	MarkParentsItemsRecursively(TreeItem);
	
EndProcedure

&AtClientAtServerNoContext
Function Check(ValueText)
	
	MatchingTags = New Map;
	MatchingTags.Insert("NotIsChecked", 0);
	MatchingTags.Insert("CheckedWithBan", 1);
	MatchingTags.Insert("ItIsCheckedWithoutBan", 2);
	MatchingTags.Insert("Default", 3);
	MatchingTags.Insert("SeveralOptions", 5);
	
	Return MatchingTags.Get(ValueText);
	
	
EndFunction

&AtClientAtServerNoContext
Procedure MarkParentsItemsRecursively(TreeItem)
	
	Parent = TreeItem.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ParentItems1 = Parent.GetItems();
	If ParentItems1.Count() = 0 Then
		Parent.CheckValue = Check("NotIsChecked");
	ElsIf TreeItem.CheckValue = Check("SeveralOptions") Then
		Parent.CheckValue = Check("SeveralOptions");
	Else
		Parent.CheckValue = CheckMarkValueRelativeToNestedItems(Parent);
	EndIf;
	
	MarkParentsItemsRecursively(Parent);
	
EndProcedure

&AtClientAtServerNoContext
Function CheckMarkValueRelativeToNestedItems(TreeItem)
	
	ReturnValue_1 = -1;
	
	For Each NestedItem In TreeItem.GetItems() Do
		
		If ReturnValue_1 = -1 Then
			ReturnValue_1 = NestedItem.CheckValue;
		ElsIf NestedItem.CheckValue = Check("SeveralOptions") Then
			ReturnValue_1 = Check("SeveralOptions");
			Break;
		ElsIf ReturnValue_1 <> NestedItem.CheckValue Then
			ReturnValue_1 = Check("SeveralOptions");
			Break;
		EndIf;
		
	EndDo;
	
	If ReturnValue_1 = -1 Then
		ReturnValue_1 = Check("NotIsChecked");
	EndIf;
	
	Return ReturnValue_1;
	
EndFunction

&AtClientAtServerNoContext
Procedure MarkNestedItemsRecursively(TreeItems, CheckValue)
	
	For Each NestedItem In TreeItems Do
		
		NestedItem.CheckValue = CheckValue;
		MarkNestedItemsRecursively(NestedItem.GetItems(), NestedItem.CheckValue);
		
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Function PictureInInterface(MetadataObject)
	
	ObjectProperties = New Structure("Picture");
	FillPropertyValues(ObjectProperties, MetadataObject);
	If ValueIsFilled(ObjectProperties.Picture) Then
		Return ObjectProperties.Picture;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServerNoContext
Function IsSubsystem(MetadataObject)
	Return StrStartsWith(MetadataObject.FullName(), "Subsystem");
EndFunction

&AtServerNoContext
Function MetadataObjectAvailable(MetadataObject)
	
	IsSubsystem = IsSubsystem(MetadataObject);
	
	If Not IsSubsystem And Not Metadata["Documents"].Contains(MetadataObject) Then
		Return False;
	EndIf;
	
	If Not IsSubsystem Then
		MetadataObjectType = Type("DocumentRef." + MetadataObject.Name);
		If Not InformationRegisters.StatusOfDocumentVerification.CreateRecordSet().Metadata().Dimensions.Document.Type.ContainsType(MetadataObjectType) Then
			Return False;
		EndIf;
	EndIf;
	
	AvailableByRights = AccessRight("View", MetadataObject);
	AvailableByFunctionalOptions = Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject);
	
	AvailableInInterface = ?(IsSubsystem, MetadataObject.IncludeInCommandInterface, MetadataObject.FullTextSearch = 
		Metadata.ObjectProperties.FullTextSearchUsing.Use);
	
	Return AvailableByRights And AvailableByFunctionalOptions And AvailableInInterface;
	
EndFunction

&AtClient
Procedure UpdateExceptionDocumentsRecursively(TreeItems)
	
	For Each TreeItem In TreeItems Do
		SubordinateTreeItems = TreeItem.GetItems();
		If SubordinateTreeItems.Count() Then
			UpdateExceptionDocumentsRecursively(SubordinateTreeItems);
		ElsIf TreeItem.CheckValue <> Check("Default") Then
			ExclusionDocuments.Insert(TreeItem.Name, TreeItem.CheckValue);
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function CheckValueSelectionList()
	
	ChoiceList = New ValueList;
	ChoiceList.Add(0, NStr("vi = 'Không kiểm tra';
							|ru = 'Не проверяется';
							|en = 'Not under check'; fa = 'تحت بررسی نیست';
							|it = 'Не проверяется';
							|pl = 'Not under check';
							|tr = 'Kontrol edilmez'"));
	ChoiceList.Add(1, NStr("vi = 'Đang kiểm tra và cấm chỉnh sửa';
							|ru = 'Проверяется с запретом редактирования';
							|en = 'Under check with editing restriction'; fa = 'تحت بررسی با محدودیت ویرایش';
							|it = 'Проверяется с запретом редактирования';
							|pl = 'Under check with editing restriction';
							|tr = 'Düzenleme yasağı ile kontrol edilir'"));
	ChoiceList.Add(2, NStr("vi = 'Kiểm tra thông báo';
							|ru = 'Уведомительная проверка';
							|en = 'Notification check'; fa = 'بررسی اعلان';
							|it = 'Уведомительная проверка';
							|pl = 'Notification check';
							|tr = 'Bildirim kontrolü'"));
	DefaultValue = ?(GetFunctionalOption("AllowModificationOfAuditedFinancialDocuments"), NStr("vi = 'thông báo';
																								|ru = 'уведомительная';
																								|en = 'notification'; fa = 'notification';
																								|it = 'уведомительная';
																								|pl = 'notification';
																								|tr = 'bildirim'"), NStr("vi = 'cấm chỉnh sửa';
																															|ru = 'запрет редактирования';
																															|en = 'editing restriction'; fa = 'editing restriction';
																															|it = 'запрет редактирования';
																															|pl = 'editing restriction';
																															|tr = 'düzenleme yasağı'"));
	ChoiceList.Add(3, NStr("vi = 'Theo mặc định';
							|ru = 'По умолчанию';
							|en = 'Default'; fa = 'پیش‌فرض';
							|it = 'Di default';
							|pl = 'Domyślnie';
							|tr = 'Varsayılan'") + " " + "(" + DefaultValue + ")");
	
	Return ChoiceList;
	
EndFunction

&AtServerNoContext
Function NamesOfDocumentsToBeChecked()
	
	NamesOfDocumentsToBeChecked = New ValueList;
	
	DocumentsTypesToBeChecked = InformationRegisters.StatusOfDocumentVerification.CreateRecordSet().Metadata().Dimensions.Document.Type.Types();
	ExcludedTypesToCheck = InformationRegisters.SettingsOfDocumentCheckExceptions.ExcludedTypesOfDocumentsForVerification(True);
	
	DocumentsTypesToBeChecked = CommonClientServer.ArraysDifference(DocumentsTypesToBeChecked, ExcludedTypesToCheck);
	
	For Each TypeOfDocumentBeingChecked In DocumentsTypesToBeChecked Do
		
		MetadataCollectionItem = Metadata.FindByType(TypeOfDocumentBeingChecked);
		
		If MetadataObjectAvailable(MetadataCollectionItem) Then
			NamesOfDocumentsToBeChecked.Add(MetadataCollectionItem.Name, MetadataCollectionItem.Presentation());
		EndIf;
		
	EndDo;
	
	NamesOfDocumentsToBeChecked.SortByValue();
	
	Return NamesOfDocumentsToBeChecked;
	
EndFunction

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ProcessRecord(Commands.WriteAndClose);		
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ExclusionDocuments()
	
	ReturnStructure = New Structure;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SettingsOfDocumentCheckExceptions.DocumentKind.Name AS Name,
	|	CASE
	|		WHEN SettingsOfDocumentCheckExceptions.IsChecked
	|				AND SettingsOfDocumentCheckExceptions.NotificationCheck
	|			THEN 2
	|		WHEN SettingsOfDocumentCheckExceptions.IsChecked
	|				AND NOT SettingsOfDocumentCheckExceptions.NotificationCheck
	|			THEN 1
	|		ELSE 0
	|	END AS CheckValue
	|FROM
	|	InformationRegister.SettingsOfDocumentCheckExceptions AS SettingsOfDocumentCheckExceptions";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ReturnStructure.Insert(Selection.Name, Selection.CheckValue);
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

&AtServerNoContext
Procedure SaveExceptionSettings(ExclusionDocuments)
	
	OldExceptions = ExclusionDocuments();
	DocumentStringOfOldExceptions = CommonClientServer.StructureKeysToString(OldExceptions);
	DocumentStringOfNewExceptions = CommonClientServer.StructureKeysToString(ExclusionDocuments);
	DocumentArrayOfOldExceptions = ?(ValueIsFilled(DocumentStringOfOldExceptions), 
										StrSplit(DocumentStringOfOldExceptions, ","), 
										New Array);
	PurgedExceptionDocuments = CommonClientServer.ArraysDifference(DocumentArrayOfOldExceptions, StrSplit(DocumentStringOfNewExceptions, ","));
	
	If ExclusionDocuments.Count() = 0 And PurgedExceptionDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	MetadataNamesArray = New Array;
	For Each DocumentExceptions In ExclusionDocuments Do
		MetadataNamesArray.Add("Document."+DocumentExceptions.Key);
	EndDo;
	For Each DocumentExceptions In PurgedExceptionDocuments Do
		If ValueIsFilled(DocumentExceptions) Then
			MetadataNamesArray.Add("Document."+DocumentExceptions);
		EndIf;
	EndDo;
	
	ExceptionSettings = InformationRegisters.SettingsOfDocumentCheckExceptions.CreateRecordSet();
	LockParameters = New Structure("TableType, TableName", "InformationRegister", "SettingsOfDocumentCheckExceptions");
	
	BeginTransaction();
	
	Try
		
		References = Common.MetadataObjectIDs(MetadataNamesArray);
		
		For Each MetadataId In References Do
			
			CheckValue = Undefined;
			SearchKey = StrReplace(MetadataId.Key, "Document.", "");
			ExclusionDocuments.Property(SearchKey, CheckValue);
			
			LockValues = New Structure("DocumentKind", MetadataId.Value);
			TMCommonUse.SetManagedLock(LockParameters, LockValues);
			
			LockDataForEdit(MetadataId.Value);
			
			ExceptionSettings.Clear();
			ExceptionSettings.Filter.DocumentKind.Set(MetadataId.Value);
			
			If CheckValue <> Undefined Then
				RegisterRecord = ExceptionSettings.Add();
				RegisterRecord.DocumentKind = MetadataId.Value;
				RegisterRecord.IsChecked = CheckValue <> Check("NotIsChecked");
				RegisterRecord.NotificationCheck = CheckValue = Check("ItIsCheckedWithoutBan");
			EndIf;
			
			ExceptionSettings.Write();
			
			UnlockDataForEdit(MetadataId.Value);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = StrTemplate(NStr("vi = 'Không thể lưu tùy chỉnh loại trừ kiểm tra các chứng từ tài chính do nguyên nhân: %1';
										|ru = 'Не удалось сохранить настройки исключений проверки финансовых документов по причине: %1';
										|en = 'Cannot save the settings of financial document check exceptions. Reason: %1'; fa = 'Cannot save the settings of financial document check exceptions. Reason: %1';
										|it = 'Не удалось сохранить настройки исключений проверки финансовых документов по причине: %1';
										|pl = 'Cannot save the settings of financial document check exceptions. Reason: %1';
										|tr = 'Finansal belgelerin kontrolüne ilişkin istisna ayarları şu nedenle kaydedilemedi: %1'"),
			DetailErrorDescription(ErrorInfo()));
			
		WriteLogEvent(
			NStr("vi = 'Tùy chỉnh loại trừ kiểm tra chứng từ';
				|ru = 'Настройка исключений проверки документов';
				|en = 'Set up document check exceptions'; fa = 'Set up document check exceptions';
				|it = 'Настройка исключений проверки документов';
				|pl = 'Set up document check exceptions';
				|tr = 'Belge kontrolüne ilişkin istisna ayarı'", CommonClientServer.DefaultLanguageCode()), 
			EventLogLevel.Error, , , MessageText);
			
		Raise NStr("vi = 'Không thể lưu tùy chỉnh loại trừ. Chi tiết xcem trong Nhật ký sự kiện';
					|ru = 'Не удалось сохранить настройки исключений. Подробнее см. в Журнале регистрации';
					|en = 'Cannot save the exception settings. For more information, see the Event log'; fa = 'Cannot save the exception settings. For more information, see the Event log';
					|it = 'Не удалось сохранить настройки исключений. Подробнее см. в Журнале регистрации';
					|pl = 'Cannot save the exception settings. For more information, see the Event log';
					|tr = 'İstisna ayarları kaydedilemedi. Ayrıntılar için Kayıt Günlüğüne bakın'");
	
	EndTry;
	
EndProcedure

#EndRegion
