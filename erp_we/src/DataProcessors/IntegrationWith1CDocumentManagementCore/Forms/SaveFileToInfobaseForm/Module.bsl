#Region FormHeaderItemsEventHandlers

&AtClient
Procedure VersionCommentOnChange(Item)
	
	CallbackDescriptionOnClose.AdditionalParameters.EditingInformation.VersionComment = VersionComment;
	
EndProcedure

#EndRegion