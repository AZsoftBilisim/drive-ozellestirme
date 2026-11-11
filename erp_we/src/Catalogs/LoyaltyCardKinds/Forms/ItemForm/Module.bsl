
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	MapTypeWhenChangedOnServer();
	
	CopyingValue = Parameters.CopyingValue;
	DiscountsMarkupsServer.WhenCreatingDiscountSourcesOnServer(ThisObject,
	                                                                ?(CopyingValue.IsEmpty(), Object.Ref, CopyingValue));
	
	If Object.Personalized Then
		PersonalizationType = "Personalized";
	Else
		PersonalizationType = "Unattended";
	EndIf;
	
	If Object.AllowAutoRegistrationAtFirstReading Then
		ActivationProcedure = "DuringTheFirstReading";
	Else
		ActivationProcedure = "UsingTheWizard";
	EndIf;
	
	Items.ActivationProcedure.Enabled = Not Object.CardType = Enums.CardTypes.Mixed;
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	Items.LoyaltyProgram.Visible = Object.Personalized;
	Items.SetStatusValid.Visible = AccessRight("Update", Metadata.Catalogs.DiscountsMarkups);
	Items.SetTheStatusNotValid.Visible = AccessRight("Update", Metadata.Catalogs.DiscountsMarkups);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands 
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	GenerateDescriptionOfSettings();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

// Parameters:
// 	EventName - String
// 	Parameter - Structure:
// 		* Source - Array
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_ValidityOfDiscountsMarkups" And Parameter.Source.Find(Object.Ref) <> Undefined Then
		UpdateDiscountTree();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	Notify("Write_LoyaltyCardKind", WriteParameters, Object.Ref);
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	DiscountsMarkupsServer.WhenRecordingOnServerOfSourcesOfValidityOfDiscountsMargins(CurrentObject, CopyingValue);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CardTypeOnChange(Item)
	
	MapTypeWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CardTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PersonalizationTypeOnChange(Item)
	
	Object.Personalized = PersonalizationType = "Personalized";
	Items.LoyaltyProgram.Visible = Object.Personalized;
	GenerateDescriptionOfSettings();
	
EndProcedure

&AtClient
Procedure ActivationProcedureOnChange(Item)
	
	Object.AllowAutoRegistrationAtFirstReading = ActivationProcedure = "DuringTheFirstReading";
	GenerateDescriptionOfSettings();
	
EndProcedure

&AtClient
Procedure StatusChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = PredefinedValue("Enum.StatusesOfLoyaltyCardKinds.Closed") Then
		
		StandardProcessing = False;
		
		ShowQueryBox(New CallbackDescription("StatusChoiceProcessingCompletion", ThisObject,
			New Structure("ValueSelected", ValueSelected)), 
			NStr("vi = 'Thẻ khách hàng thân thiết đang có hiệu lực sẽ bị xóa, tiếp tục?';
				|ru = 'Действующие карты лояльности будут аннулированы, продолжить?';
				|en = 'Currently valid loyalty cards will be canceled. Continue?'; fa = 'Currently valid loyalty cards will be canceled. Continue?';
				|it = 'Le carte fedeltà in vigore verranno cancellate, continuare?';
				|pl = 'Ważne karty lojalności zostaną anulowane, kontynuować?';
				|tr = 'Mevcut sadakat kartları iptal edilecek, devam edilsin mi?'"), QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	ValueSelected = AdditionalParameters.ValueSelected;
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		Object.Status = ValueSelected;
	EndIf;

EndProcedure

&AtClient
Procedure OptionForDisplayingDiscountsOnChange(Item)
	
	UpdateDiscountTree();
	
EndProcedure

&AtClient
Procedure SliceDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateDiscountTree();
	
EndProcedure

&AtClient
Procedure InformationOnDiscountValidityURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	If Var_URL = "ConfigureDiscounts" Then
			
			OpenForm("Catalog.DiscountsMarkups.ListForm", ,ThisObject);
			
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTablePartDiscountsMargins

&AtClient
Procedure DiscountsMarkupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If ValueIsFilled(Items.DiscountsMarkups.CurrentData.Ref) Then
		ShowValue(Undefined, Items.DiscountsMarkups.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsOnActivateRow(Item)
	
	AttachIdleHandler("Attachable_ListOnActivateRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsBeforeExpand(Item, String, Cancel)
	
	DiscountsMarkupsClient.SaveWhetherTreeNodeIsExpandedInList(String, Items.DiscountsMarkups, ExpandedTreeNodes, True);
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsBeforeCollapse(Item, String, Cancel)
	
	DiscountsMarkupsClient.SaveWhetherTreeNodeIsExpandedInList(String, Items.DiscountsMarkups, ExpandedTreeNodes, False);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckRangeOverlap(Command)
	
	ClearMessages();
	CheckIntersectionOfRangesOnServer();
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	ClearMessages();
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"));
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure DiscountMarkupValidityHistory(Command)
	
	ClearMessages();
	DiscountsMarkupsClient.OpenStatusChangeHistoryForm(ThisForm);
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	ClearMessages();
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisForm,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		Object.Ref);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotValid(Command)
	
	ClearMessages();
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisForm,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"),
		Object.Ref);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands 

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	DiscountsMarkupsServer.SetConditionalAppearanceOfDiscountSourceForm(ConditionalAppearance, Items);

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure MapTypeWhenChangedOnServer()
	
	Items.TemplatesOfLoyaltyCardCodesMagneticCodeLength.Visible = Object.CardType = Enums.CardTypes.Magnetic Or Object.CardType = Enums.CardTypes.Mixed;
	Items.TemplatesOfLoyaltyCardCodesStartOfMagneticCodeRange.Visible = Object.CardType = Enums.CardTypes.Magnetic Or Object.CardType = Enums.CardTypes.Mixed;
	Items.TemplatesOfLoyaltyCardCodesEndOfMagneticCodeRange.Visible = Object.CardType = Enums.CardTypes.Magnetic Or Object.CardType = Enums.CardTypes.Mixed;
	Items.LoyaltyCardCodeTemplatesMagneticCardCodeTemplate.Visible = Object.CardType = Enums.CardTypes.Magnetic Or Object.CardType = Enums.CardTypes.Mixed;
	
	Items.TemplatesOfLoyaltyCardCodesBarcodeLength.Visible = Object.CardType = Enums.CardTypes.Barcode_ Or Object.CardType = Enums.CardTypes.Mixed;
	Items.TemplatesOfLoyaltyCardCodesStartOfBarcodeRange.Visible = Object.CardType = Enums.CardTypes.Barcode_ Or Object.CardType = Enums.CardTypes.Mixed;
	Items.TemplatesOfLoyaltyCardCodesEndOfBarcodeRange.Visible = Object.CardType = Enums.CardTypes.Barcode_ Or Object.CardType = Enums.CardTypes.Mixed;
	
	Items.ActivationProcedure.Enabled = Not Object.CardType = Enums.CardTypes.Mixed;
	If Object.CardType = Enums.CardTypes.Mixed Then
		Object.AllowAutoRegistrationAtFirstReading = False;
		ActivationProcedure = "UsingTheWizard";
	EndIf;
	
EndProcedure

#EndRegion

#Region PropertySubsystemProcedures

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure BuildDiscountMarkUpTree()
	
	DiscountsMarkupsServer.BuildDiscountMarkUpTreeInForm(
	                                            ThisObject,
	                                            ?(CopyingValue.IsEmpty(),Object.Ref, CopyingValue));
	InformationOnDiscountNumber = DiscountsMarkupsServer.InformationOnDiscountNumber(
	                                            ?(CopyingValue.IsEmpty(),Object.Ref, CopyingValue),
	                                            SliceDate);
	UpdateUsageOfDiscountsMarkups(ActivatedDiscountMarkup);
	
EndProcedure

&AtServer
Procedure CheckIntersectionOfRangesOnServer()
	
	For Each TSRow In Object.TemplatesOfLoyaltyCardCodes Do
		
		Query = New Query(
		"
		|SELECT
		|	VALUE(Enum.CardCodeTypes.Barcode) AS CodeType,
		|	TemplatesOfLoyaltyCardCodes.Ref AS CardKind,
		|	TemplatesOfLoyaltyCardCodes.LineNumber AS LineNumber,
		|	TemplatesOfLoyaltyCardCodes.CodeLength AS CodeLength,
		|	TemplatesOfLoyaltyCardCodes.StartOfRange_ AS StartOfRange_,
		|	TemplatesOfLoyaltyCardCodes.RangeEnd AS RangeEnd
		|FROM
		|	(SELECT
		|		TemplatesOfLoyaltyCardCodes.Ref AS Ref,
		|		TemplatesOfLoyaltyCardCodes.LineNumber AS LineNumber,
		|		TemplatesOfLoyaltyCardCodes.BarcodeLength AS CodeLength,
		|		TemplatesOfLoyaltyCardCodes.StartOfBarcodeRange AS StartOfRange_,
		|		TemplatesOfLoyaltyCardCodes.EndOfBarcodeRange AS RangeEnd
		|	FROM
		|		Catalog.LoyaltyCardKinds.TemplatesOfLoyaltyCardCodes AS TemplatesOfLoyaltyCardCodes
		|	WHERE
		|		&CheckBarcodes
		|	) AS TemplatesOfLoyaltyCardCodes
		|WHERE
		|	TemplatesOfLoyaltyCardCodes.CodeLength = &BarcodeLength
		|	AND CASE
		|			WHEN TemplatesOfLoyaltyCardCodes.Ref = &CardKind
		|					AND TemplatesOfLoyaltyCardCodes.LineNumber = &LineNumber
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN TemplatesOfLoyaltyCardCodes.StartOfRange_ < &StartOfBarcodeRange
		|					AND TemplatesOfLoyaltyCardCodes.RangeEnd < &StartOfBarcodeRange
		|				THEN FALSE
		|			ELSE CASE
		|					WHEN TemplatesOfLoyaltyCardCodes.StartOfRange_ > &EndOfBarcodeRange
		|							AND TemplatesOfLoyaltyCardCodes.RangeEnd > &EndOfBarcodeRange
		|						THEN FALSE
		|					ELSE TRUE
		|				END
		|		END
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.CardCodeTypes.MagneticCode) AS CodeType,
		|	TemplatesOfLoyaltyCardCodes.Ref AS CardKind,
		|	TemplatesOfLoyaltyCardCodes.LineNumber AS LineNumber,
		|	TemplatesOfLoyaltyCardCodes.CodeLength AS CodeLength,
		|	TemplatesOfLoyaltyCardCodes.StartOfRange_ AS StartOfRange_,
		|	TemplatesOfLoyaltyCardCodes.RangeEnd AS RangeEnd
		|FROM
		|	(SELECT
		|		TemplatesOfLoyaltyCardCodes.Ref AS Ref,
		|		TemplatesOfLoyaltyCardCodes.LineNumber AS LineNumber,
		|		TemplatesOfLoyaltyCardCodes.MagneticCodeLength AS CodeLength,
		|		TemplatesOfLoyaltyCardCodes.StartOfMagneticCodeRange AS StartOfRange_,
		|		TemplatesOfLoyaltyCardCodes.EndOfMagneticCodeRange AS RangeEnd
		|	FROM
		|		Catalog.LoyaltyCardKinds.TemplatesOfLoyaltyCardCodes AS TemplatesOfLoyaltyCardCodes
		|	WHERE
		|		&CheckMagneticCodes
		|	) AS TemplatesOfLoyaltyCardCodes
		|WHERE
		|	TemplatesOfLoyaltyCardCodes.CodeLength = &MagneticCodeLength
		|	AND CASE
		|			WHEN TemplatesOfLoyaltyCardCodes.Ref = &CardKind
		|					AND TemplatesOfLoyaltyCardCodes.LineNumber = &LineNumber
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN TemplatesOfLoyaltyCardCodes.StartOfRange_ < &StartOfMagneticCodeRange
		|					AND TemplatesOfLoyaltyCardCodes.RangeEnd < &StartOfMagneticCodeRange
		|				THEN FALSE
		|			ELSE CASE
		|					WHEN TemplatesOfLoyaltyCardCodes.StartOfRange_ > &EndOfMagneticCodeRange
		|							AND TemplatesOfLoyaltyCardCodes.RangeEnd > &EndOfMagneticCodeRange
		|						THEN FALSE
		|					ELSE TRUE
		|				END
		|		END
		
		|");
		
		Query.SetParameter("MagneticCodeLength"          , TSRow.MagneticCodeLength);
		Query.SetParameter("StartOfMagneticCodeRange", TSRow.StartOfMagneticCodeRange);
		Query.SetParameter("EndOfMagneticCodeRange" , TSRow.EndOfMagneticCodeRange);
		
		Query.SetParameter("BarcodeLength"          , TSRow.BarcodeLength);
		Query.SetParameter("StartOfBarcodeRange", TSRow.StartOfBarcodeRange);
		Query.SetParameter("EndOfBarcodeRange" , TSRow.EndOfBarcodeRange);
		
		Query.SetParameter("CheckBarcodes" ,    Object.CardType = Enums.CardTypes.Barcode_ Or Object.CardType = Enums.CardTypes.Mixed);
		Query.SetParameter("CheckMagneticCodes", Object.CardType = Enums.CardTypes.Magnetic Or Object.CardType = Enums.CardTypes.Mixed);
		
		Query.SetParameter("LineNumber" ,    TSRow.LineNumber);
		Query.SetParameter("CardKind" ,       Object.Ref);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			If Selection.CodeType = Enums.CardCodeTypes.MagneticCode Then
				
				If Selection.CardKind <> Object.Ref Then
					MessageText = NStr("vi = 'Dải mã từ %2 - %3 trong dòng %1 giao với dải mã từ của thẻ ""%5"" %6 - %7 trong dòng %4';
										|ru = 'Диапазон магнитных кодов %2 - %3 в строке %1 пересекается с диапазоном магнитных кодов карт ""%5"" %6 - %7 в строке %4';
										|en = 'Magnetic code range %2 - %3 in line %1 overlaps with the magnetic code range %6 - %7 of card ""%5"" in line %4'; fa = 'Magnetic code range %2 - %3 in line %1 overlaps with the magnetic code range %6 - %7 of card ""%5"" in line %4';
										|it = 'Intervallo di codici magnetici %2 - %3 nella riga %1 si interseca con l''intervallo di codici magnetici delle carte ""%5"" %6 - %7 nella riga %4';
										|pl = 'Zakres kodów magnetycznych %2 - %3 w wierszu %1 pokrywa się z zakresem kodów magnetycznych kart ""%5"" %6 - %7 w wierszu %4';
										|tr = '%1 satırındaki %2 - %3 manyetik kod aralığı, %4 satırındaki %6 - %7 ""%5"" kartlarının manyetik kod aralığıyla kesişmektedir'");
				Else
					If Selection.LineNumber > TSRow.LineNumber Then
						Continue;
					EndIf;
					MessageText = NStr("vi = 'Dải mã từ %2 - %3 trong dòng %1 giao nhau với dải mã từ %6 - %7 trong dòng %4';
										|ru = 'Диапазон магнитных кодов %2 - %3 в строке %1 пересекается с диапазоном магнитных кодов %6 - %7 в строке %4';
										|en = 'Magnetic code range %2 - %3 in line %1 overlaps with the range of magnetic code range %6 - %7 in line %4'; fa = 'Magnetic code range %2 - %3 in line %1 overlaps with the range of magnetic code range %6 - %7 in line %4';
										|it = 'Intervallo di codici magnetici %2 - %3 nella riga %1 si interseca con l''intervallo di codici magnetici %6 - %7 nella riga %4';
										|pl = 'Zakres kodów magnetycznych %2 - %3 w wierszu %1 pokrywa się z zakresem kodów magnetycznych %6 - %7 w wierszu %4';
										|tr = '%1 satırındaki %2 - %3 manyetik kod aralığı, %4 satırındaki %6 - %7 manyetik kod aralığıyla kesişmektedir'");
				EndIf;
				
				TemplateText = StringFunctionsClientServer.SubstituteParametersToString(
					MessageText,
					TSRow.LineNumber,                   //%1
					TSRow.StartOfMagneticCodeRange, //%2
					TSRow.EndOfMagneticCodeRange,  //%3
					Selection.LineNumber,                    //%4
					Selection.CardKind,                       //%5
					Selection.StartOfRange_,                //%6
					Selection.RangeEnd); //%7
				
				CommonClientServer.MessageToUser(TemplateText, Object.Ref, CommonClientServer.PathToTabularSection("Object.TemplatesOfLoyaltyCardCodes", TSRow.LineNumber, "StartOfMagneticCodeRange"));
				
			Else
				
				If Selection.CardKind <> Object.Ref Then
					MessageText = NStr("vi = 'Dải mã vạch %2 - %3 trong dòng %1 giao với dải mã vạch của thẻ ""%5"" %6 - %7 trong dòng %4';
										|ru = 'Диапазон штрихкодов %2 - %3 в строке %1 пересекается с диапазоном штрихкодов карт ""%5"" %6 - %7 в строке %4';
										|en = 'Barcode range %2 - %3 in line %1 overlaps with the barcode range %6 - %7 of cards ""%5"" in line %4'; fa = 'Barcode range %2 - %3 in line %1 overlaps with the barcode range %6 - %7 of cards ""%5"" in line %4';
										|it = 'Intervallo dei codici a barre %2 - %3 nella riga %1 si interseca con l''intervallo dei codici a barre delle carte ""%5"" %6 - %7 nella riga %4';
										|pl = 'Zakres kodów kreskowych %2 - %3 w wierszu %1 pokrywa się z zakresem kodów kreskowym kart ""%5"" %6 - %7 w wierszu %4';
										|tr = '%1 satırındaki %2 - %3 barkod aralığı, %4 satırındaki %6 - %7 ""%5"" kartlarının barkod aralığıyla kesişmektedir'");
				Else
					If Selection.LineNumber > TSRow.LineNumber Then
						Continue;
					EndIf;
					MessageText = NStr("vi = 'Dải mã vạch %2 - %3 trong dòng %1 giao với dải mã vạch %6 - %7 trong dòng %4';
										|ru = 'Диапазон штрихкодов %2 - %3 в строке %1 пересекается с диапазоном штрихкодов %6 - %7 в строке %4';
										|en = 'Barcode range %2 - %3 in line %1 overlaps with the barcode range %6 - %7 in line %4'; fa = 'Barcode range %2 - %3 in line %1 overlaps with the barcode range %6 - %7 in line %4';
										|it = 'Intervallo dei codici a barre %2 - %3 nella riga %1 si interseca con l''intervallo dei codici a barre %6 - %7 nella riga %4';
										|pl = 'Zakres kodów kreskowych %2 - %3 w wierszu %1 pokrywa się z zakresem kodów kreskowych %6 - %7 w wierszu %4';
										|tr = '%1 satırındaki %2 - %3 barkod aralığı, %4 satırındaki %6 - %7 barkod aralığıyla kesişmektedir'");
				EndIf;
				
				TemplateText = StringFunctionsClientServer.SubstituteParametersToString(
					MessageText,
					TSRow.LineNumber,                   //%1
					TSRow.StartOfBarcodeRange,      //%2
					TSRow.EndOfBarcodeRange,       //%3
					Selection.LineNumber,                    //%4
					Selection.CardKind,                       //%5
					Selection.StartOfRange_,                //%6
					Selection.RangeEnd); //%7
				
				CommonClientServer.MessageToUser(TemplateText, Object.Ref, CommonClientServer.PathToTabularSection("Object.TemplatesOfLoyaltyCardCodes", TSRow.LineNumber, "StartOfBarcodeRange"));
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure GenerateDescriptionOfSettings()
	
	If Object.Personalized And Object.AllowAutoRegistrationAtFirstReading Then
		SettingsDescription = NStr("vi = 'Thẻ dạng này có thể là tích lũy
		                              |được kích hoạt khi đọc lần đầu vào chứng từ bán hàng hoặc thông qua trợ giúp ghi nhận';
		                              |ru = 'Карты данного вида могут быть накопительными
		                              |и активируются при первом считывании в документе продажи или с помощью помощника регистрации';
		                              |en = 'Cards of this kind can be tiered.
		                              |They are activated when first read in a sales document or through the loyalty card registration wizard'; fa = 'Cards of this kind can be tiered.
		                              |They are activated when first read in a sales document or through the loyalty card registration wizard';
		                              |it = 'Le carte di questo tipo possono essere cumulative
		                              |e vengono attivate alla prima lettura nel documento di vendita o con l''ausilio dell''assistente di registrazione';
		                              |pl = 'Karty danego rodzaju mogą być kumulacyjnymi
		                              |i są aktywowane przy pierwszym sczytywaniu w dokumencie sprzedaży lub za pomocą asystenta rejestracji';
		                              |tr = 'Bu tür kartlar birikimli olabilir
		                              |ve satış belgesinde ilk kez okunma sırasında veya kayıt sihirbazı aracılığıyla etkinleştirilir'");
	ElsIf Object.Personalized And Not Object.AllowAutoRegistrationAtFirstReading Then
		SettingsDescription = NStr("vi = 'Thẻ dạng này có thể là tích lũy
		                              |và được kích hoạt thông qua trợ giúp ghi nhận thẻ khách hàng thân thiết.';
		                              |ru = 'Карты данного вида могут быть накопительными
		                              |и активируются с помощью помощника регистрации карт лояльности.';
		                              |en = 'Cards of this kind can be tiered.
		                              |They are activated through the loyalty card registration wizard'; fa = 'Cards of this kind can be tiered.
		                              |They are activated through the loyalty card registration wizard';
		                              |it = 'Le carte di questo tipo possono essere cumulative
		                              |e vengono attivate con l''ausilio dell''assistente di registrazione delle carte fedeltà.';
		                              |pl = 'Karty danego rodzaju mogą być kumulacyjnymi
		                              |i są aktywowane za pomocą asystenta rejestracji kart lojalnościowych.';
		                              |tr = 'Bu tür kartlar birikimli olabilir
		                              |ve sadakat kartı kayıt sihirbazı aracılığıyla etkinleştirilir.'");
	ElsIf Not Object.Personalized And Object.AllowAutoRegistrationAtFirstReading Then
		SettingsDescription = NStr("vi = 'Thẻ dạng này không thể là tích lũy
		                              |được kích hoạt khi đọc lần đầu vào chứng từ bán hàng hoặc thông qua trợ giúp ghi nhận';
		                              |ru = 'Карты данного вида не могут быть накопительными
		                              |и активируются при первом считывании в документе продажи или с помощью помощника регистрации';
		                              |en = 'Cards of this kind cannot be tiered.
		                              |They are activated when first read in a sales document or through the loyalty card registration wizard'; fa = 'Cards of this kind cannot be tiered.
		                              |They are activated when first read in a sales document or through the loyalty card registration wizard';
		                              |it = 'Le carte di questo tipo non possono essere cumulative
		                              |e vengono attivate alla prima lettura nel documento di vendita o con l''ausilio dell''assistente di registrazione';
		                              |pl = 'Karty danego rodzaju nie mogą być kumulacyjnymi
		                              |i są aktywowane przy pierwszym sczytywaniu w dokumencie sprzedaży lub za pomocą asystenta rejestracji';
		                              |tr = 'Bu tür kartlar birikimli olamaz
		                              |ve satış belgesinde ilk kez okunma sırasında veya kayıt sihirbazı aracılığıyla etkinleştirilir'");
	ElsIf Not Object.Personalized And Not Object.AllowAutoRegistrationAtFirstReading Then
		SettingsDescription = NStr("vi = 'Thẻ dạng này không thể là tích lũy
		                              |và được kích hoạt thông qua trợ giúp ghi nhận thẻ khách hàng thân thiết.';
		                              |ru = 'Карты данного вида не могут быть накопительными
		                              |и активируются с помощью помощника регистрации карт лояльности.';
		                              |en = 'Cards of this kind cannot be tiered.
		                              |They are activated through the loyalty card registration wizard'; fa = 'Cards of this kind cannot be tiered.
		                              |They are activated through the loyalty card registration wizard';
		                              |it = 'Le carte di questo tipo non possono essere cumulative
		                              |e vengono attivate con l''ausilio dell''assistente di registrazione delle carte fedeltà.';
		                              |pl = 'Karty danego rodzaju nie mogą być 
		                              |i są aktywowane za pomocą asystenta rejestracji kart lojalnościowych.';
		                              |tr = 'Bu tür kartlar birikimli olamaz
		                              |ve sadakat kartı kayıt sihirbazı aracılığıyla etkinleştirilir.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	CurrentData = Items.DiscountsMarkups.CurrentData;
	DiscountMarkup = ?(CurrentData = Undefined Or CurrentData.IsFolder, Undefined, CurrentData.Ref);
	
	If DiscountMarkup <> ActivatedDiscountMarkup Then
		UpdateUsageOfDiscountsMarkups(DiscountMarkup);
		ActivatedDiscountMarkup = ?(CurrentData = Undefined, Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateUsageOfDiscountsMarkups(DiscountMarkup)
	
	UsingMarkUpDiscount = DiscountsMarkupsServer.UsingMarkUpDiscount(DiscountMarkup, SliceDate);
	DiscountsMarkupsServer.CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                                UsingMarkUpDiscount,
	                                                                                "ConfigureDiscounts");
	
EndProcedure

&AtClient
Procedure UpdateDiscountTree()
	
	BuildDiscountMarkUpTree();
	DiscountsMarkupsClient.ExpandDiscountTreeRecursively(DiscountsMarkups, Items.DiscountsMarkups, ExpandedTreeNodes);
	DiscountsMarkupsClient.PositionOnValueInTree(ActivatedDiscountMarkup, DiscountsMarkups, Items.DiscountsMarkups, "Ref");
	
EndProcedure 

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If Result = True Then
		
		Attributes = ObjectAttributesLockClient.Attributes(ThisForm, , False);		
		ObjectAttributesLockClient.SetAttributeEditEnabling(ThisForm, Attributes);
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Attributes);
		
	EndIf;
	
EndProcedure
#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_SliceDate" Then
		SliceDateOnChange(Items.SliceDate);
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
