
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.AttributeName = "LineOfBusiness" Then
		Title = NStr("vi = 'Lịch sử thay đổi  lĩnh vực kinh doanh';
					|ru = 'История изменения направления деятельности';
					|en = 'Change history of line of business'; fa = 'Change history of line of business';
					|it = 'Storia di modifica del settore dell''attività';
					|pl = 'Historia zmiany rodzaju działalności';
					|tr = 'Faaliyet yönündeki değişim geçmişi'");
	EndIf; 
	
	ChangeHistory.Load(Catalogs.Assets.HistoryOfChangingProps(Parameters.FixedAsset, Parameters.AttributeName));
	
	AssetsLocalization.WhenCreatedOnServer_ChangeHistory(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChangeHistory

&AtClient
Procedure ChangeHistorySelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, Items.ChangeHistory.CurrentData.Document);
	
EndProcedure

#EndRegion
