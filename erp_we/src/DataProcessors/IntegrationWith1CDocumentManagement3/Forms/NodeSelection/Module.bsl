#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
	ModuleIntegrationWith1CDocumentManagement3.ToEstablishConditionalAppearanceOfHoldingSSUBAssets(ThisObject);
	
	TreeOfSubAssetsIsCODE = FormAttributeToValue("CODESUBAssets");
	
	For Each StringParametersSubAssetsCODE In Parameters.CODESUBAssets.GetItems() Do
		If IsBlankString(StringParametersSubAssetsCODE.NodeID) Then
			Continue;
		EndIf;
		FillInSUBAsset(TreeOfSubAssetsIsCODE.Rows.Add(), StringParametersSubAssetsCODE);
	EndDo;
	
	ValueToFormAttribute(TreeOfSubAssetsIsCODE, "CODESUBAssets");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCODESUBAssets

&AtClient
Procedure CODESUBAssetsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectCompletion();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	
	SelectCompletion();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectCompletion()
	
	CurrentData = Items.CODESUBAssets.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.WebServiceAddress) Then
		Close(CurrentData.NodeID);
	Else
		ShowMessageBox(, NStr("vi = 'Chỉ có thể chọn nút đang hoạt động';
								|ru = 'Выбрать можно только активный узел';
								|en = 'You can only select an active node'; fa = 'You can only select an active node';
								|it = 'Выбрать можно только активный узел';
								|pl = 'You can only select an active node';
								|tr = 'Sadece aktif düğüm seçilebilir'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSUBAsset(StringTreeSubAssetsCODE, StringParametersSubAssetsCODE)
	
	FillPropertyValues(StringTreeSubAssetsCODE, StringParametersSubAssetsCODE);
	
	For Each SubordinateStringParametersSUBAssetsCODE In StringParametersSubAssetsCODE.GetItems() Do
		FillInSUBAsset(StringTreeSubAssetsCODE.Rows.Add(), SubordinateStringParametersSUBAssetsCODE);
	EndDo;
	
EndProcedure

#EndRegion