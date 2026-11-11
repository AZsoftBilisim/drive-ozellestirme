#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		GeneralOnly = False;
		
		If Parameters.Property("CopyingValue") Then
		
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalIncidentAttributes, 
				Parameters.CopyingValue.PropertiesSet, 
				PropertyManager.PropertiesSetByName("Catalog_Incidents_Overall"),
				"Attributes",
				GeneralOnly);
				
		EndIf;
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AdditionalAttributesAndInfoSets"
		Or EventName = "Write_AdditionalAttributesAndInfo" Then
		
		// When recording a set of extras .details (information), for example: 
		// opened the general add-on editing form.details (information) and recorded it.
		WhenRecordingSetOfAdditionalDetailsAndInformationOnServer();
		
	ElsIf EventName = "Write_IncidentKinds" Then
		
		Read();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_IncidentKinds");
	Read();
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalAttribute5");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Parameters:
//  Item - FormField
//  StandardProcessing - Boolean
&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CommandsForAdditionalDetailsAndInformation

&AtClient
Procedure CreateNewIncidentAttribute(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5");
	
EndProcedure

&AtClient
Procedure CreateSharedIncidentAttribute(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "Common");
		
EndProcedure

&AtClient
Procedure CreateIncidentAttributeBasedOnSample(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "FromMaster");
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForEditingTablesAndDetails

&AtClient
Function FormTableForAdditionalInformationDetails(ElementType)
	
	If ElementType = "AdditionalAttribute5" Then
		Return Items.TableOfAdditionalIncidentAttributes;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function AddlAttributesTable(Form, ElementType)
	
	If ElementType = "AdditionalAttribute5" Then
		Return Form.TableOfAdditionalIncidentAttributes;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function SetOfAdditionalItemDetails_(Object)
	
	Return Object.PropertiesSet;

EndFunction

&AtServerNoContext
Function SetOfAdditionalDetailsInformationGeneral()
	
	Return PropertyManager.PropertiesSetByName("Catalog_Incidents_Overall");
	
EndFunction

&AtClient
Procedure AddAdditionalDetailsInformation(ElementType, Kind = "")
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể thêm thuộc tính bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Добавление дополнительных свойств возможно только после записи элемента.
		|Записать элемент?';
		|en = 'Data is not saved yet.
		|You can add additional properties only after the item is saved.
		|Do you want to save the item?'; fa = 'Data is not saved yet.
		|You can add additional properties only after the item is saved.
		|Do you want to save the item?';
		|it = 'I dati non sono ancora stati registrati.
		|L''aggiunta di proprietà aggiuntive è possibile solo dopo la scrittura dell''elemento.
		|Scrivere l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane/
		|Dodanie dodatkowych właściwości jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler kaydedilmedi.
		|Ek özellikler eklemek ancak öğe kaydedildikten sonra mümkündür.
		|Öğeyi kaydet?'");
		
		ShowQueryBox(New CallbackDescription("AddAdditionalDetailsInformationCompletion", ThisObject, New Structure("Kind, ElementType", Kind, ElementType)), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	AddAdditionalPropsSummaryFragment(Kind, ElementType);
	
EndProcedure

&AtClient
Procedure AddAdditionalPropsSummaryFragment(Val Kind, Val ElementType)

	SetOfAdditionalInformationDetails = SetOfAdditionalItemDetails_(Object); // CatalogRef.AdditionalAttributesAndInfoSets
	If Not ValueIsFilled(SetOfAdditionalInformationDetails) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	If Kind = "Common" Then
		SetOfAdditionalInformationDetails = SetOfAdditionalDetailsInformationGeneral();
	ElsIf Kind = "FromMaster" Then
		If ElementType = "AdditionalAttribute5" Then 
			FormParameters.Insert("SelectAdditionalValuesOwner", True);
		Else
			FormParameters.Insert("SelectSharedProperty", True);
		EndIf;
	EndIf;
	
	FormParameters.Insert("PropertiesSet", SetOfAdditionalInformationDetails);
	FormParameters.Insert("CurrentPropertiesSet", SetOfAdditionalInformationDetails);
	FormParameters.Insert("IsAdditionalInfo", ElementType <> "AdditionalAttribute5");
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
					FormParameters,
					FormTableForAdditionalInformationDetails(ElementType),
					,
					,
					,
					,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
//  QuestionResult - DialogReturnCode -
//  AdditionalParameters - Structure:
//		* Kind - String
//		* ElementType - String
&AtClient
Procedure AddAdditionalDetailsInformationCompletion(QuestionResult, AdditionalParameters) Export

	Kind = AdditionalParameters.Kind;
	ElementType = AdditionalParameters.ElementType;

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;

	If Not ItemRecorded Then
		Return;
	EndIf;

	AddAdditionalPropsSummaryFragment(Kind, ElementType);

EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInListsOfAdditionalInformationDetails();
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure FillInListsOfAdditionalInformationDetails()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalIncidentAttributes, 
		Object.PropertiesSet, 
		PropertyManager.PropertiesSetByName("Catalog_Incidents_Overall"),
		"Attributes",
		False);
	
EndProcedure
	
&AtServer
Procedure CustomizeForm()
	
	#Region AdditionalDetailsAndAdditionalInformation
	
	UseAdditionalAttributesAndInfo = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	
	Items.GroupAddAttributes.Visible = UseAdditionalAttributesAndInfo;

	YouHaveRightToAddBankingDetails = AccessRight("Insert", Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo);
	
	Items.TypeOfIncidentsCreateAttributes.Visible 	= YouHaveRightToAddBankingDetails;
	
	#EndRegion

EndProcedure

&AtServer
Procedure FillInListOfPropertiesAndDetailsOfTable(Table, SetOfPropertiesAndProps, SetOfCommonPropertiesAndProps, 
	DataType, OnlyCommonProperties = False)
	
	// If you need to re-fill the properties, then check that a reference to a set of properties has been passed.
	If Not OnlyCommonProperties Then
		If Not ValueIsFilled(SetOfPropertiesAndProps) Then
			Return;
		EndIf;
	Else
		// If you need to re-fill only COMMON properties, then check that a reference to a set of COMMON properties has been passed.
		If Not ValueIsFilled(SetOfCommonPropertiesAndProps) Then
			Return;
		EndIf;
	EndIf;
	
	If OnlyCommonProperties Then
		
		// Delete only the rows of common properties from the table.
		UBound = Table.Count() - 1;
		
		For IndexOf = 0 To UBound Do
			
			TableRow = Table[UBound - IndexOf];
			
			If TableRow.CommonProperty Then
				Table.Delete(TableRow);
			EndIf;
			
		EndDo;
		
	Else
		
		Table.Clear();
		
	EndIf;
	
	// Get a list of additional details from a set of properties, and additional details from a set of general properties.
	Query = New Query;
	
	Query.SetParameter("SetOfCommonProperties", SetOfCommonPropertiesAndProps);
	
	If OnlyCommonProperties Then
	
		Query.Text = 
		"SELECT
		|	GeneralAdditionalInformation.Property AS Property,
		|	GeneralAdditionalInformation.Property.Title AS AttributeRepresentation,
		|	TRUE AS CommonProperty,
		|	GeneralAdditionalInformation.LineNumber AS RowNumberToSort,
		|	CASE WHEN GeneralAdditionalInformation.DeletionMark THEN 4 ELSE 1 END AS PictureIndex
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS GeneralAdditionalInformation
		|WHERE
		|	GeneralAdditionalInformation.Ref = &SetOfCommonProperties";
		
	Else
		
		Query.SetParameter("PropertiesSet", SetOfPropertiesAndProps);
		
		Query.Text = 
		"SELECT
		|	AdditionalInformation_.Property AS Property,
		|	AdditionalInformation_.Property.Title AS AttributeRepresentation,
		|	FALSE AS CommonProperty,
		|	AdditionalInformation_.LineNumber AS RowNumberToSort,
		|	CASE WHEN AdditionalInformation_.DeletionMark THEN 4 ELSE 1 END AS PictureIndex
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalInformation_
		|WHERE
		|	AdditionalInformation_.Ref = &PropertiesSet
		|
		|UNION ALL
		|
		|SELECT
		|	GeneralAdditionalInformation.Property,
		|	GeneralAdditionalInformation.Property.Title,
		|	TRUE,
		|	GeneralAdditionalInformation.LineNumber,
		|	CASE WHEN GeneralAdditionalInformation.DeletionMark THEN 4 ELSE 1 END
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS GeneralAdditionalInformation
		|WHERE
		|	GeneralAdditionalInformation.Ref = &SetOfCommonProperties";
		
	EndIf;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	TableOfAdditionalInformationDetails = QueryResult.Unload();
	
	If OnlyCommonProperties Then
		
		TableOfAdditionalInformationDetails.Sort("RowNumberToSort Asc");
		
		TableOfAllAdditionalInformationDetails = Table.Unload();
		TableOfAllAdditionalInformationDetails.Clear();
		
		CommonClientServer.SupplementTable(TableOfAdditionalInformationDetails, TableOfAllAdditionalInformationDetails);
		CommonClientServer.SupplementTable(Table, TableOfAllAdditionalInformationDetails);
		
		Table.Load(TableOfAllAdditionalInformationDetails);
		
	Else
		
		TableOfAdditionalInformationDetails.Sort("CommonProperty Desc, RowNumberToSort Asc");
		
		Table.Load(TableOfAdditionalInformationDetails);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordAdditionalSetDetails(Cancel, CurrentObject, ElementType)
	
	SetOfPropertiesAndInformationDetails = SetOfAdditionalItemDetails_(CurrentObject);
	If Not ValueIsFilled(SetOfPropertiesAndInformationDetails) Then
		Return;
	EndIf;
	
	ObjectPropertySet = SetOfPropertiesAndInformationDetails.GetObject();
	
	TSAdditionalAttributesInfo = ObjectPropertySet.AdditionalAttributes;
	
	AddlAttributesTable = AddlAttributesTable(ThisForm, ElementType);
	TSAdditionalAttributesInfo.Clear();
	
	For Each RowElement In AddlAttributesTable Do
		If Not RowElement.CommonProperty Then
			NwRw = TSAdditionalAttributesInfo.Add();
			NwRw.Property = RowElement.Property;
			NwRw.DeletionMark = Common.ObjectAttributeValue(RowElement.Property, "DeletionMark");
		EndIf;
	EndDo;
	
	Try
		
		ObjectPropertySet.Write();
		
	Except
		
		// Set the sign of record failure.
		Cancel = True;
		
		// Add an entry to the log.
		
		LanguageCode = Common.DefaultLanguageCode();
		
		EventName = StrTemplate("%1.%2",
								NStr("vi = 'Mục tin bổ sung của sự cố';
									|ru = 'Дополнительные реквизиты инцидентов';
									|en = 'Additional incident attributes'; fa = 'Additional incident attributes';
									|it = 'Requisiti aggiuntivi incidenti';
									|pl = 'Dodatkowe atrybuty incydentów';
									|tr = 'Ek olay öznitelikleri'", LanguageCode),
								NStr("vi = 'Không thể cập nhật thành phần mục tin bổ sung của tập hợp.';
									|ru = 'Не удалось обновить состав дополнительных реквизитов набора.';
									|en = 'Cannot update additional attributes of the kit.'; fa = 'Cannot update additional attributes of the kit.';
									|it = 'Non è stato possibile aggiornare la composizione dei requisiti aggiuntivi di selezione.';
									|pl = 'Nie udało się zaktualizować dodatkowych atrybutów zestawu.';
									|tr = 'Ek set özniteliklerinin bileşimi güncellenemedi.'", LanguageCode));
		
	
		JournalComment  = NStr("vi = 'Khi cập nhật phần bảng các mục tin bổ sung trong tập hợp thuộc tính ""%1"" đã xảy ra lỗi: ""%2""';
								|ru = 'При обновлении табличной части дополнительных реквизитов набора свойств ""%1"" произошла ошибка: ""%2""';
								|en = 'An error occurred when updating the table of the additional attributes of property set ""%1"": ""%2""'; fa = 'An error occurred when updating the table of the additional attributes of property set ""%1"": ""%2""';
								|it = 'Durante l''aggiornamento della tabella delle proprietà aggiuntive dell''insieme delle proprietà ""%1"" si è verificato un errore: ""%2""';
								|pl = 'Podczas aktualizacji sekcji tabelarycznej atrybutów dodatkowych zestawu właściwości ""%1"" zaistniał błąd: ""%2""';
								|tr = '""%1"" özellik kümesinin ek özniteliklerinin tablo bölümü güncellenirken hata oluştu: ""%2""'");
		ErrorPresentation = DetailErrorDescription(ErrorInfo());
		
		JournalComment  = StringFunctionsClientServer.SubstituteParametersToString(
			JournalComment, 
			SetOfPropertiesAndInformationDetails, 
			ErrorPresentation);
		
		WriteLogEvent(
			EventName, 
			EventLogLevel.Error, 
			, 
			SetOfPropertiesAndInformationDetails, 
			JournalComment, 
			EventLogEntryTransactionMode.Transactional);
		
		// Raise an exception.
		ExceptionExpression = NStr("vi = 'Khi ghi lại mục tin bổ sung của sự cố, đã xảy ra lỗi (xem nhật ký sự kiện).';
									|ru = 'При записи дополнительных реквизитов инцидента произошла ошибка (см. журнал регистрации).';
									|en = 'An error occurred when saving additional incident attributes (see the event log).'; fa = 'An error occurred when saving additional incident attributes (see the event log).';
									|it = 'Si è verificato un errore durante la registrazione dei requisiti aggiuntivi dell''incidente (vedi registro).';
									|pl = 'Podczas zapisu dodatkowych atrybutów incydentu wystąpił błąd (zob. dziennik rejestracji).';
									|tr = 'Ek olay öznitelikleri kaydedilirken  hata oluştu ( olay günlüğe bakın).'");
		
		Raise(ExceptionExpression);
		
	EndTry;
	
EndProcedure

&AtServer
Procedure WhenRecordingSetOfAdditionalDetailsAndInformationOnServer()
	
	If Not Modified Then
		Read();
	Else
		FillInListsOfAdditionalInformationDetails();
	EndIf;
	
EndProcedure

#EndRegion