#import "TGTokenFieldView.h"

#import "TGTokenView.h"
#import "TGBackspaceTextField.h"
#import "TGHacks.h"

#import <QuartzCore/QuartzCore.h>

@interface TGTokenFieldScrollView : UIScrollView

@end

@implementation TGTokenFieldScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)__unused view
{
    return true;
}

- (void)scrollRectToVisible:(CGRect)__unused rect animated:(BOOL)__unused animated
{
}

@end

@interface TGTokenFieldView () <UITextFieldDelegate, UIKeyInput>

@property (nonatomic, strong) NSMutableDictionary *tokenAnimations;

@property (nonatomic, strong) NSMutableArray *tokenList;
@property (nonatomic, strong) TGBackspaceTextField *textField;
@property (nonatomic, strong) UILabel *counterLabel;

@property (nonatomic) float lineHeight;
@property (nonatomic) float linePadding;
@property (nonatomic) float lineSpacing;
@property (nonatomic) int maxNumberOfLines;

@property (nonatomic) int currentNumberOfLines;

@end

@implementation TGTokenFieldView

@synthesize delegate = _delegate;

@synthesize scrollView = _scrollView;

@synthesize tokenAnimations = _tokenAnimations;

@synthesize tokenList = _tokenList;
@synthesize textField = _textField;
@synthesize counterLabel = _counterLabel;

@synthesize lineHeight = _lineHeight;
@synthesize linePadding = _linePadding;
@synthesize lineSpacing = _lineSpacing;
@synthesize maxNumberOfLines = _maxNumberOfLines;

@synthesize currentNumberOfLines = _currentNumberOfLines;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _lineHeight = 26;
    _linePadding = 9;
    _lineSpacing = 11;
    _maxNumberOfLines = 2;
    
    _currentNumberOfLines = 1;
    
    self.clipsToBounds = false;
    self.backgroundColor = [UIColor whiteColor];
    
    UIImageView *shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TokenFieldShadow.png"]];
    shadowView.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, shadowView.frame.size.height);
    shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:shadowView];
    
    _scrollView = [[TGTokenFieldScrollView alloc] initWithFrame:self.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches = true;
    _scrollView.canCancelContentTouches = true;
    _scrollView.scrollsToTop = false;
    _scrollView.backgroundColor = [UIColor whiteColor];
    _scrollView.opaque = true;
    [self addSubview:_scrollView];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    tapRecognizer.cancelsTouchesInView = false;
    [_scrollView addGestureRecognizer:tapRecognizer];
    
    _textField = [[TGBackspaceTextField alloc] initWithFrame:CGRectMake(0, 0, 10, 42)];
    _textField.text = @"";
    _textField.delegate = self;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.backgroundColor = [UIColor whiteColor];
    _textField.font = [UIFont systemFontOfSize:15];
    [_scrollView addSubview:_textField];
    
    _textField.customPlaceholderLabel.frame = CGRectOffset(_textField.customPlaceholderLabel.frame, 9 + 5, 9 + 4);
    [_scrollView addSubview:_textField.customPlaceholderLabel];
    
    _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 50 - 9, 12, 50, 20)];
    _counterLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _counterLabel.font = [UIFont systemFontOfSize:15];
    _counterLabel.text = @"0/99";
    _counterLabel.textAlignment = UITextAlignmentRight;
    _counterLabel.userInteractionEnabled = false;
    _counterLabel.textColor = UIColorRGB(0x8d9298);
    _counterLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_counterLabel];
    
    _tokenList = [[NSMutableArray alloc] init];
}

- (void)addToken:(NSString *)title tokenId:(id)tokenId animated:(bool)animated
{
    TGTokenView *tokenView = [[TGTokenView alloc] initWithFrame:CGRectMake(0, 0, 20, 28)];
    tokenView.label = title;
    tokenView.tokenId = tokenId;
    [_tokenList addObject:tokenView];
    [_scrollView addSubview:tokenView];
    
    if (animated)
    {
        if (_tokenAnimations == nil)
            _tokenAnimations = [[NSMutableDictionary alloc] init];
        
        if (tokenId != nil)
            [_tokenAnimations setObject:[[NSNumber alloc] initWithInt:1] forKey:tokenId];
    }
    
    [_textField setShowPlaceholder:false animated:_textField.text.length == 0];
    [self updateCounter];
    
    [self setNeedsLayout];
}

- (void)updateCounter
{
    _counterLabel.text = [[NSString alloc] initWithFormat:@"%d/99", _tokenList.count];
}

- (NSArray *)tokenIds
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:_tokenList.count];
    
    for (TGTokenView *tokenView in _tokenList)
    {
        if (tokenView.tokenId != nil)
            [array addObject:tokenView.tokenId];
    }
    
    return array;
}

- (void)removeTokensAtIndexes:(NSIndexSet *)indexSet
{
    NSUInteger lastCount = _tokenList.count;
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, __unused BOOL *stop)
    {
        TGTokenView *tokenView = [_tokenList objectAtIndex:index];
        if ([tokenView isFirstResponder])
            [tokenView resignFirstResponder];
        
        [UIView animateWithDuration:0.2 animations:^
        {
            tokenView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
            tokenView.alpha = 0.0f;
        } completion:^(__unused BOOL finished)
        {
            [tokenView removeFromSuperview];
        }];
    }];
    
    [_tokenList removeObjectsAtIndexes:indexSet];
    
    if (_tokenAnimations == nil)
        _tokenAnimations = [[NSMutableDictionary alloc] init];
    
    [self setNeedsLayout];
    
    if (_tokenList.count == 0)
        [_textField setShowPlaceholder:true animated:lastCount != _tokenList.count];
    [self updateCounter];
}

- (float)preferredHeight
{
    int visibleNumberOfLines = MIN(MAX(1, _currentNumberOfLines), _maxNumberOfLines);
    return _lineHeight * visibleNumberOfLines + MAX(0, visibleNumberOfLines - 1) * _lineSpacing + _linePadding * 2;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self doLayout:_tokenAnimations != nil];
    
    if (_tokenAnimations != nil)
    {
        for (TGTokenView *tokenView in _tokenList)
        {
            if (tokenView.tokenId == nil)
                continue;
            
            NSNumber *nAnimation = [_tokenAnimations objectForKey:tokenView.tokenId];
            if (nAnimation != nil)
            {
                tokenView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
                tokenView.alpha = 0.0f;
            }
        }
        
        [UIView animateWithDuration:0.2 animations:^
        {
            for (TGTokenView *tokenView in _tokenList)
            {
                if (tokenView.tokenId == nil)
                    continue;
                
                NSNumber *nAnimation = [_tokenAnimations objectForKey:tokenView.tokenId];
                if (nAnimation != nil)
                {
                    tokenView.transform = CGAffineTransformIdentity;
                    tokenView.alpha = 1.0f;
                }
            }
        }];
        
        _tokenAnimations = nil;
    }
}

- (void)doLayout:(bool)animated
{
    float width = self.frame.size.width;
    
    const float textFieldMinWidth = 60;
    const float padding = 9;
    const float textFieldPadding = 5;
    const float spacing = 6;
    
    int currentLine = 0;
    float currentX = padding;
    float currentY = _linePadding;
    
    float additionalPadding = 44;
    
    CGRect targetFrames[_tokenList.count];
    memset(targetFrames, 0, sizeof(CGRect) * _tokenList.count);
    
    int index = -1;
    for (TGTokenView *tokenView in _tokenList)
    {
        index++;
        
        float tokenWidth = [tokenView preferredWidth];
        
        if (width - padding - currentX - additionalPadding < MAX(tokenWidth, textFieldMinWidth) && currentX > padding + FLT_EPSILON)
        {
            currentLine++;
            currentY += _lineHeight + _lineSpacing;
            currentX = padding;
        }
        
        CGRect tokenFrame = CGRectMake(currentX, currentY - 1, MIN(tokenWidth, width - padding - currentX - additionalPadding), tokenView.frame.size.height);
        
        if (animated && tokenView.frame.origin.x > FLT_EPSILON)
            targetFrames[index] = tokenFrame;
        else
            tokenView.frame = tokenFrame;
        currentX += tokenFrame.size.width + spacing;
    }
    
    bool lastLineContainsTextFieldOnly = false;
    
    if (width - padding - currentX - additionalPadding < textFieldMinWidth)
    {
        currentLine++;
        currentY += _lineHeight + _lineSpacing;
        currentX = padding;
        
        lastLineContainsTextFieldOnly = true;
    }
    
    if (currentLine + 1 != _currentNumberOfLines)
        animated = true;
    
    CGRect textFieldFrame = CGRectMake(currentX + textFieldPadding, currentY + 4 - 10, width - padding - currentX - textFieldPadding * 2 - additionalPadding + 4, _textField.frame.size.height);
    _textField.frame = textFieldFrame;
    if (animated)
    {
        _textField.alpha = 0.0f;
        
        [UIView animateWithDuration:0.2 animations:^
        {
            _textField.alpha = 1.0f;
        }];
    }
    
    if (lastLineContainsTextFieldOnly && ![self hasFirstResponder])
    {
        currentLine--;
        currentY -= _lineHeight + _lineSpacing;
    }
    
    if (animated)
    {
        [UIView beginAnimations:@"tokenField" context:nil];
        [UIView setAnimationDuration:0.15];
        
        int index = -1;
        for (TGTokenView *tokenView in _tokenList)
        {
            index++;
            
            if (targetFrames[index].origin.x > FLT_EPSILON)
                tokenView.frame = targetFrames[index];
        }
    }
    
    currentY += _lineHeight + _linePadding;
    
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, currentY);
    
    if (animated)
    {
        [UIView commitAnimations];
    }
    
    if (MIN(currentLine + 1, _maxNumberOfLines) != MIN(_currentNumberOfLines, _maxNumberOfLines))
    {
        id <TGTokenFieldViewDelegate> delegate = _delegate;
        
        [delegate tokenFieldView:self didChangeHeight:_lineHeight * MIN(currentLine + 1, _maxNumberOfLines) + MAX(0, currentLine) * _lineSpacing + _linePadding * 2];
    }
    else if (currentLine + 1 > _currentNumberOfLines)
    {
        [self scrollToTextField:true];
    }
    
    _currentNumberOfLines = currentLine + 1;
}

- (bool)hasFirstResponder
{
    return _textField.isFirstResponder;
    
    //return [self findFirstResponder:_scrollView] != nil;
}

- (UIView *)findFirstResponder:(UIView *)view
{
    if ([view isFirstResponder])
        return view;
    
    for (UIView *subview in view.subviews)
    {
        UIView *result = [self findFirstResponder:subview];
        if (result != nil)
            return result;
    }
    
    return nil;
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _textField)
    {
        //[self addToken:_textField.text];

        bool wasEmpty = textField.text.length == 0;
        textField.text = @"";
        
        if (_delegate != nil)
        {
            id <TGTokenFieldViewDelegate> delegate = _delegate;
            
            [delegate tokenFieldView:self didChangeText:textField.text];
            if (wasEmpty != textField.text.length == 0)
                [delegate tokenFieldView:self didChangeSearchStatus:[self searchIsActive] byClearingTextField:true];
        }
        
        [self scrollToTextField:false];
        
        _textField.hidden = true;
        dispatch_async(dispatch_get_main_queue(), ^
        {
            _textField.hidden = false;
        });
    }
    
    return false;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == _textField)
    {
        bool wasEmpty = textField.text.length == 0;
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        [self scrollToTextField:true];
        
        id <TGTokenFieldViewDelegate> delegate = _delegate;
        
        if (delegate != nil)
        {
            [delegate tokenFieldView:self didChangeText:textField.text];
            if (wasEmpty != textField.text.length == 0)
                [delegate tokenFieldView:self didChangeSearchStatus:[self searchIsActive] byClearingTextField:true];
        }
    }
    
    return false;
}

- (void)textFieldDidHitLastBackspace
{
    if (_tokenList.count != 0)
    {
        [[_tokenList lastObject] becomeFirstResponder];
    }
}

- (void)textFieldDidBecomeFirstResponder
{
    [self setNeedsLayout];
}

- (void)textFieldDidResignFirstResponder
{
    if (_tokenAnimations == nil)
        _tokenAnimations = [[NSMutableDictionary alloc] init];
    
    [self setNeedsLayout];
}

- (void)scrollToTextField:(bool)animated
{
    CGPoint contentOffset = _scrollView.contentOffset;
    CGSize contentSize = _scrollView.contentSize;
    CGSize frameSize = _scrollView.frame.size;
    if (contentOffset.y < contentSize.height - frameSize.height)
        contentOffset = CGPointMake(0, contentSize.height - frameSize.height);
    if (contentOffset.y < 0)
        contentOffset.y = 0;
    
    if (!animated)
        [_scrollView setContentOffset:contentOffset animated:animated];
    else
    {
        [UIView animateWithDuration:0.2 animations:^
        {
            [_scrollView setContentOffset:contentOffset animated:false];
        }];
    }
}

- (bool)searchIsActive
{
    return /*_textField.isFirstResponder && */_textField.text.length != 0;
}

- (void)clearText
{
    _textField.text = @"";
    
    id <TGTokenFieldViewDelegate> delegate = _delegate;
    
    if (delegate != nil)
        [delegate tokenFieldView:self didChangeSearchStatus:[self searchIsActive] byClearingTextField:false];
}

- (void)highlightToken:(TGTokenView *)tokenView
{
    for (TGTokenView *view in _tokenList)
    {
        if (view != tokenView)
        {
            if (view.selected)
                view.selected = false;
        }
    }
    
    tokenView.selected = true;
    
    [self setNeedsLayout];
}

- (void)unhighlightToken:(TGTokenView *)tokenView
{
    tokenView.selected = false;
    
    if (_tokenAnimations == nil)
        _tokenAnimations = [[NSMutableDictionary alloc] init];
    
    [self setNeedsLayout];
}

- (void)deleteToken:(TGTokenView *)tokenView
{
    int index = -1;
    for (TGTokenView *view in _tokenList)
    {
        index++;
        
        if (view == tokenView)
        {
            [_tokenList removeObjectAtIndex:index];
            break;
        }
    }
    
    [tokenView removeFromSuperview];
    [_textField becomeFirstResponder];
    
    [self setNeedsLayout];
    
    id <TGTokenFieldViewDelegate> delegate = _delegate;
    
    if (delegate != nil)
        [delegate tokenFieldView:self didDeleteTokenWithId:tokenView.tokenId];
    
    if (_tokenList.count == 0)
        [_textField setShowPlaceholder:true animated:false];
    [self updateCounter];
}

- (void)beginTransition:(NSTimeInterval)duration
{
    _counterLabel.hidden = true;
    UIImage *inputFieldImage = nil;
    UIImageView *temporaryImageView = nil;
    
    UIGraphicsBeginImageContextWithOptions(_scrollView.bounds.size, true, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    inputFieldImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    temporaryImageView = [[UIImageView alloc] initWithImage:inputFieldImage];
    temporaryImageView.frame = _scrollView.bounds;
    
    UIView *temporaryImageViewContainer = [[UIView alloc] initWithFrame:_scrollView.frame];
    temporaryImageViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    temporaryImageViewContainer.clipsToBounds = true;
    [temporaryImageViewContainer addSubview:temporaryImageView];
    
    [self insertSubview:temporaryImageViewContainer aboveSubview:_scrollView];
    _scrollView.alpha = 0.0f;
    
    [UIView animateWithDuration:duration animations:^
    {
        temporaryImageView.alpha = 0.0f;
        _scrollView.alpha = 1.0f;
    } completion:^(__unused BOOL finished)
    {
        [temporaryImageView removeFromSuperview];
        [temporaryImageViewContainer removeFromSuperview];
    }];
    _counterLabel.hidden = false;
}

- (void)tapRecognized:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [_textField becomeFirstResponder];
    }
}

- (BOOL)hasText
{
    return false;
}

- (void)insertText:(NSString *)__unused text
{
}

- (void)deleteBackward
{
}

@end
