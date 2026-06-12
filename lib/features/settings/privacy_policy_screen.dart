import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'プライバシーポリシー',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('プライバシーポリシー'),
        _BodyText(
          '本アプリ「ランニングモンスター」（以下「本アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の適切な保護に努めます。本ポリシーは、本アプリにおける個人情報の取り扱いについて説明します。',
        ),
        SizedBox(height: 24),
        _SectionTitle('1. 収集する情報'),
        _BodyText(
          '本アプリは以下の情報を収集・利用します。\n\n'
          '• 位置情報（GPS）：ランニングルートの記録および距離計算のために使用します。位置情報はデバイス内にのみ保存され、外部サーバーには送信されません。\n\n'
          '• カメラ：QRコードのスキャンに使用します。撮影した画像は保存されません。\n\n'
          '• 通知：ランニングリマインダーや実績達成の通知に使用します。',
        ),
        SizedBox(height: 24),
        _SectionTitle('2. 情報の利用目的'),
        _BodyText(
          '収集した情報は以下の目的にのみ使用します。\n\n'
          '• ランニング記録の保存・管理\n'
          '• ゲームプレイ（モンスター育成・EXP計算）\n'
          '• プッシュ通知の送信\n'
          '• 広告の表示（Google AdMob）',
        ),
        SizedBox(height: 24),
        _SectionTitle('3. 広告について'),
        _BodyText(
          '本アプリはGoogle AdMobを利用した広告を表示します。AdMobは広告配信のために、デバイス識別子や広告IDを利用する場合があります。詳細はGoogleのプライバシーポリシーをご確認ください。',
        ),
        SizedBox(height: 24),
        _SectionTitle('4. データの保存'),
        _BodyText(
          'ランニング記録、モンスターデータ、ゲームの進行状況等のデータはすべてデバイス内のローカルストレージに保存されます。外部サーバーへのデータ送信は行いません（広告SDKを除く）。',
        ),
        SizedBox(height: 24),
        _SectionTitle('5. 第三者への提供'),
        _BodyText(
          '本アプリは、法令に基づく場合を除き、ユーザーの個人情報を第三者に提供しません。',
        ),
        SizedBox(height: 24),
        _SectionTitle('6. 子どものプライバシー'),
        _BodyText(
          '本アプリは13歳未満の子どもを対象としていません。13歳未満のユーザーから意図せず個人情報を収集した場合は、速やかに削除します。',
        ),
        SizedBox(height: 24),
        _SectionTitle('7. 本ポリシーの変更'),
        _BodyText(
          '本ポリシーは予告なく変更する場合があります。重要な変更がある場合は、アプリ内でお知らせします。',
        ),
        SizedBox(height: 24),
        _SectionTitle('8. お問い合わせ'),
        _BodyText(
          '本ポリシーに関するお問い合わせは、アプリストアのサポートページよりご連絡ください。',
        ),
        SizedBox(height: 24),
        _SectionTitle('利用規約'),
        _BodyText(
          '本アプリをご利用いただくにあたり、以下の利用規約に同意いただく必要があります。',
        ),
        SizedBox(height: 16),
        _SectionTitle('第1条（適用）'),
        _BodyText(
          '本規約は、本アプリの利用条件を定めるものです。ユーザーは本規約に同意した上で本アプリをご利用ください。',
        ),
        SizedBox(height: 16),
        _SectionTitle('第2条（利用上の注意）'),
        _BodyText(
          '• 本アプリを利用したランニング中は、交通ルールを遵守し安全に配慮してください。\n'
          '• 体調が優れない場合は無理な運動を避けてください。\n'
          '• 本アプリは医療目的ではありません。健康上の問題がある場合は医師にご相談ください。',
        ),
        SizedBox(height: 16),
        _SectionTitle('第3条（禁止事項）'),
        _BodyText(
          '以下の行為を禁止します。\n\n'
          '• 本アプリの改変、リバースエンジニアリング\n'
          '• 不正な方法によるゲーム内通貨・アイテムの取得\n'
          '• 他のユーザーへの迷惑行為\n'
          '• その他、法令または公序良俗に反する行為',
        ),
        SizedBox(height: 16),
        _SectionTitle('第4条（免責事項）'),
        _BodyText(
          '本アプリの利用により生じた損害について、開発者は一切の責任を負いません。ランニング中の事故・怪我等についても同様です。',
        ),
        SizedBox(height: 40),
        Center(
          child: Text(
            '最終更新日: 2026年6月12日',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }
}
