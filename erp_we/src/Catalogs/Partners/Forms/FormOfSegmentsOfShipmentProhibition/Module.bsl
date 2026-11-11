#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ReadOnly = Not AccessRight("Update", Metadata.Catalogs.PartnersSegments);
	
	NumberOfShipmentBanSegments = SegmentsServer.NumberOfShipmentBanSegments();
	UseOneSegmentOfShipmentProhibition = NumberOfShipmentBanSegments = 1;
	NoShipmentBanSegments = NumberOfShipmentBanSegments = 0;
	Partner = Parameters.Partner;
	ClientName = Common.ObjectAttributeValue(Partner, "Description");
	PartnerIsNotAllowedToShip = SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Partner);
	
	AccessRightPartnerSegments = AccessRight("Update", Metadata.Catalogs.PartnersSegments);
	Items.CustomerSegments.Visible = AccessRightPartnerSegments;
	
	If PartnerIsNotAllowedToShip Then
		Items.BanPageGroup.CurrentPage = Items.GroupShipmentProhibited;
	Else
		Items.BanPageGroup.CurrentPage = Items.ShipmentPermittedGroup;
	EndIf;
	
	Items.LabelDecoration.Title = StrReplace(Items.LabelDecoration.Title,"%1%", ClientName);
	Items.LabelDecoration1.Title = StrReplace(Items.LabelDecoration1.Title,"%1%", ClientName);
	Items.ShipmentIsProhibited.ReadOnly = ReadOnly;
	Items.SegmentTable.ReadOnly = ReadOnly;
	
	If UseOneSegmentOfShipmentProhibition Then
		Items.AGroupOfPageSegmentsOfTheProhibitionOfShipment.CurrentPage = Items.PageProhibitionOfShipmentSegmentGroup;
		ShipmentProhibitionSegment = Catalogs.PartnersSegments.GetShipmentBanSegment();
		GenerationMethod = Common.ObjectAttributeValue(ShipmentProhibitionSegment, "GenerationMethod");
		ShipmentIsProhibited = ?(PartnerIsNotAllowedToShip, "Prohibited", "Permitted");
		SegmentIsFormedManually = (GenerationMethod = Enums.SegmentGenerationMethods.GenerateManually);
		Items.ShipmentPermissionProhibitionGroup.Visible = SegmentIsFormedManually;
		
	ElsIf NoShipmentBanSegments Then 
		Items.AGroupOfPageSegmentsOfTheProhibitionOfShipment.CurrentPage = Items.TheGroupHasNoSegmentsOfTheBan;
	Else
		Items.AGroupOfPageSegmentsOfTheProhibitionOfShipment.CurrentPage = Items.TheGroupTheSegmentsOfTheProhibitionOfShipment;
		UpdateListOfSegments();
	EndIf;
	
	If ReadOnly 
		Or (UseOneSegmentOfShipmentProhibition And Not SegmentIsFormedManually)
		Or NoShipmentBanSegments Then
		
		Items.FormCommandWrite.Title = NStr("vi = 'Đồng ý';
											|ru = 'ОК';
											|en = 'OK'; fa = 'تأیید';
											|it = 'OK';
											|pl = 'OK';
											|tr = 'Tamam'");
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit And Not ClosingInProgress And Modified And Not SaveParameters Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatma'"));
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Sẽ không thay đổi cấm giao hàng cho khách. Đóng biểu mẫu mà không lưu lại kết quả?';
																						|ru = 'Запрет отгрузки клиенту не будет изменен. Закрыть форму без сохранения результата?';
																						|en = 'Delivery block will not be changed. Close the form without saving the result?'; fa = 'Delivery block will not be changed. Close the form without saving the result?';
																						|it = 'Il divieto di spedizione al cliente non verrà modificato. Chiudere il modulo senza salvare il risultato?';
																						|pl = 'Zakaz wysyłania do klienta nie zostanie zmieniony. Zamknąć formularz bez zapisywania rezultatu?';
																						|tr = 'Müşteriye olan teslimat engeli değiştirilmeyecektir. Sonuç kaydedilmeden form kapatılsın mı?'"), ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "Close" Then
		ClosingInProgress = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSegments

&AtClient
Procedure SegmentTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.SegmentTable.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If Field.Name = "SegmentTablePartnersSegment" Then
		ShowValue(Undefined, CurrentData.PartnersSegment);
	EndIf;
	
EndProcedure

&AtClient
Procedure SegmentTableShipmentClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SegmentTableShipmentOnChange(Item)
	
	CurrentData = Items.SegmentTable.CurrentData; 
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	If CurrentData.Shipment = "Permitted" Then
		CurrentData.PictureIndex = 0;
	Else
		CurrentData.PictureIndex = 1;
	EndIf;
	
	If SegmentTable.Total("PictureIndex") = 0 Then
		Items.BanPageGroup.CurrentPage = Items.ShipmentPermittedGroup;
	Else
		Items.BanPageGroup.CurrentPage = Items.GroupShipmentProhibited;
	EndIf;
EndProcedure

&AtClient
Procedure ShipmentIsProhibitedOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure SegmentTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure SegmentTableBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure SegmentTableOnActivateRow(Item)
	CurrentData = Items.SegmentTable.CurrentData;
	
	If CurrentData <> Undefined
		And CurrentData.GenerationMethod = PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly") Then
		
		Items.ShipmentProhibitionPages.CurrentPage = Items.ShipmentProhibitionPage;
		
	Else
		
		Items.ShipmentProhibitionPages.CurrentPage = Items.PageShipmentProhibitionEmpty;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandWrite(Command)
	
	If Not ReadOnly Then
		IncludeDeleteInSegmentClient();
		SaveParameters = True;
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure CustomerSegments(Command)
	OpenForm("Catalog.PartnersSegments.ListForm");
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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SegmentTableShipment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SegmentTable.GenerationMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SegmentGenerationMethods.UpdateRegularly;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure UpdateListOfSegments()

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	PartnersSegments.Ref AS Segment
	|INTO PartnersSegments
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|WHERE
	|	NOT PartnersSegments.DeletionMark
	|	AND PartnersSegments.SegmentIsUsedToProhibitShipment
	|
	|GROUP BY
	|	PartnersSegments.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SegmentPartners.Segment,
	|	SegmentPartners.Partner
	|INTO SegmentPartners
	|FROM
	|	InformationRegister.SegmentPartners AS SegmentPartners
	|WHERE
	|	SegmentPartners.Partner = &Partner
	|
	|GROUP BY
	|	SegmentPartners.Segment,
	|	SegmentPartners.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PartnersSegments.Segment AS PartnersSegment,
	|	PartnersSegments.Segment.GenerationMethod AS GenerationMethod,
	|	CASE
	|		WHEN SegmentPartners.Partner = &Partner
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS BelongsToSegment,
	|	CASE
	|		WHEN SegmentPartners.Partner = &Partner
	|			THEN ""Prohibited""
	|		ELSE ""Permitted""
	|	END AS Shipment,
	|	CASE
	|		WHEN SegmentPartners.Partner = &Partner
	|			THEN 1
	|		ELSE 0
	|	END AS PictureIndex,
	|	PartnersSegments.Segment.LongDesc AS LongDesc
	|FROM
	|	PartnersSegments AS PartnersSegments
	|		LEFT JOIN SegmentPartners AS SegmentPartners
	|		ON (SegmentPartners.Segment = PartnersSegments.Segment)";
	
	Query.SetParameter("Partner", Partner);
	QueryResult = Query.Execute().Unload();
	
	SegmentTable.Load(QueryResult);
	
EndProcedure

#Region Other

&AtClient
Procedure IncludeDeleteInSegmentClient()
	
	If SegmentTable.Count() = 0 And Not UseOneSegmentOfShipmentProhibition Then
		Return;
	EndIf;
	
	ArrayOfAllowedSegments = New Array;
	ArrayOfProhibitedSegments = New Array;
	
	If UseOneSegmentOfShipmentProhibition And ValueIsFilled(ShipmentProhibitionSegment)Then
		If PartnerIsNotAllowedToShip And ShipmentIsProhibited = "Permitted" Then
			ArrayOfAllowedSegments.Add(ShipmentProhibitionSegment);
		ElsIf Not PartnerIsNotAllowedToShip And ShipmentIsProhibited = "Prohibited" Then
			ArrayOfProhibitedSegments.Add(ShipmentProhibitionSegment);
		EndIf;
	ElsIf Not UseOneSegmentOfShipmentProhibition Then
		For Each CurRow In SegmentTable Do
			
			If CurRow.BelongsToSegment And CurRow.Shipment = "Permitted" Then
				ArrayOfAllowedSegments.Add(CurRow.PartnersSegment);
			ElsIf Not CurRow.BelongsToSegment And CurRow.Shipment = "Prohibited" Then
				ArrayOfProhibitedSegments.Add(CurRow.PartnersSegment);
			Else
				Continue;
			EndIf;
			
		EndDo;
	EndIf;
	
	If ArrayOfProhibitedSegments.Count() > 0 Or ArrayOfAllowedSegments.Count() > 0 Then
		
		IncludeDeleteInSegmentServer(ArrayOfAllowedSegments, ArrayOfProhibitedSegments);
		
	EndIf;
	
	If ArrayOfProhibitedSegments.Count() > 0 Then
		Notify("AddingPartnerToSegment");
	EndIf;
	
	If ArrayOfAllowedSegments.Count() > 0 Then
		Notify("RemovingPartnerFromSegment");
	EndIf;
	
EndProcedure

&AtServer
Procedure IncludeDeleteInSegmentServer(ArrayOfAllowedSegments, ArrayOfProhibitedSegments);
	
	For Each ArrayElement In ArrayOfAllowedSegments Do
		
		SegmentsServer.RemovePartnerFromSegment(ArrayElement,Partner);
		
	EndDo;
	
	For Each ArrayElement In ArrayOfProhibitedSegments Do
		
		SegmentsServer.AddPartnerToSegment(ArrayElement,Partner);
		
	EndDo;
	
	UpdateListOfSegments();
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
