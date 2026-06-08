<?php
namespace App\Notifications;
use Illuminate\Auth\Notifications\ResetPassword as BaseReset;

class ResetPasswordNotification extends BaseReset
{
    public function toMail($notifiable)
    {
        $url = "myapp://reset-password?token={$this->token}&email={$notifiable->email}";
        // $url = "https://yoursite.com/reset-password?token={$this->token}&email={$notifiable->email}";

        return (new \Illuminate\Notifications\Messages\MailMessage)
            ->subject('Reset Password')
            ->line('Click the button below to reset your password.')
            ->action('Reset Password', $url)
            ->line('This link expires in 60 minutes.');
    }
}