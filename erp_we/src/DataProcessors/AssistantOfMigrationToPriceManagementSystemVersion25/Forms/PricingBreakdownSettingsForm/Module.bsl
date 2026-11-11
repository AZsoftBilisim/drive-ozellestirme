#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FeatureOption 	= Parameters.FeatureOption;
	VersionOfTheSeries 			= Parameters.VersionOfTheSeries;
	PackagingOption 		= Parameters.VersionOfTheSeries;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCaption(FeatureOption, Items.DecorationCharacteristics);
	UpdateCaption(VersionOfTheSeries, Items.SetOfTheSeries);
	UpdateCaption(PackagingOption, Items.PackagingDecoration);
	
EndProcedure


&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	StandardProcessing = False;

	
	SelectionResult = New Structure;
	SelectionResult.Insert("FeatureOption", 	FeatureOption);
	SelectionResult.Insert("VersionOfTheSeries", 			VersionOfTheSeries);
	SelectionResult.Insert("PackagingOption", 		PackagingOption);

	Close(SelectionResult);
	
EndProcedure

&AtClient
Procedure FeatureOptionOnChange(Item)
	UpdateCaption(FeatureOption, Items.DecorationCharacteristics);
EndProcedure

&AtClient
Procedure VersionOfTheSeriesOnChange(Item)
	UpdateCaption(VersionOfTheSeries, Items.SetOfTheSeries);
EndProcedure

&AtClient
Procedure PackagingOptionOnChange(Item)
	UpdateCaption(PackagingOption, Items.PackagingDecoration);
EndProcedure


&AtClient
Procedure UpdateCaption(AttributeValue, Decoration)
	
	If AttributeValue = 0 Then
		Decoration.Title = NStr("vi = '(bỏ dấu)';
								|ru = '(снять)';
								|en = '(clear)'; fa = '(clear)';
								|it = '(togliere)';
								|pl = '(clear)';
								|tr = '(kaldır)'");
	ElsIf AttributeValue = 1 Then
		Decoration.Title = NStr("vi = '(đặt dấu)';
								|ru = '(установить)';
								|en = '(set)'; fa = '(تنظیم)';
								|it = '(installare)';
								|pl = '(set)';
								|tr = '(yapılandır)'");
	Else	
		Decoration.Title = NStr("vi = '(không thay đổi)';
								|ru = '(не изменять)';
								|en = '(do not change)'; fa = '(do not change)';
								|it = '(non modificare)';
								|pl = '(nie zmieniaj)';
								|tr = '(değiştirme)'");
	EndIf;
	
EndProcedure

#EndRegion